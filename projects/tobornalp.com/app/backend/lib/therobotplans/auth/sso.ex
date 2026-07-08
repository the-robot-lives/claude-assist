defmodule Therobotplans.Auth.SSO do
  alias Therobotplans.Schema.Users.User, as: UserSchema
  alias Therobotplans.Schema.Users.Credentials.UserCredential, as: CredentialSchema
  alias Therobotplans.Schema.Versioned.Names.Name
  import Ecto.Query, only: [from: 2]

  @provider_map %{
    oidc: &Therobotplans.Auth.Providers.oidc/0,
    saml: &Therobotplans.Auth.Providers.saml/0,
    google: &Therobotplans.Auth.Providers.google/0,
    facebook: &Therobotplans.Auth.Providers.facebook/0,
    github: &Therobotplans.Auth.Providers.github/0,
    linkedin: &Therobotplans.Auth.Providers.linkedin/0
  }

  def authenticate_sso(provider_type, %{email: email} = attrs) do
    context = Noizu.Context.system()
    email = email |> String.trim() |> String.downcase()
    provider_ref = @provider_map[provider_type].()
    {:ok, provider_id} = Therobotplans.Auth.Providers.Provider.id(provider_ref)

    case find_user_by_email(email) do
      {:ok, user} ->
        # Returning user — link credential if missing, issue a session (login).
        ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context)
        create_sso_session(user, provider_type, context)

      :not_found ->
        # Brand-new identity. No users are pre-provisioned (SSO-only), so the
        # first sign-in *is* account creation. Gate it by domain allowlist:
        # allowlisted domains may register directly; everyone else must supply
        # an invite code at the /auth/register step (checked in register_user/2).
        if domain_allowed?(email) do
          {:registration_required, %{provider: to_string(provider_type), sub: sso_subject(attrs), email: email}}
        else
          # Non-allowlisted domain: still allow registration, but require an
          # invite code (the frontend will enforce the field; the backend
          # re-checks in register_user/2). Carry a flag so the form knows.
          {:registration_required, %{provider: to_string(provider_type), sub: sso_subject(attrs), email: email, invite_required: true}}
        end
    end
  end

  @doc """
  Completes registration for a verified SSO identity (carried by a
  RegistrationToken). Creates the user + SSO credential + session.
  If `invite_token` is supplied, validates it and grants org membership.
  Returns `{:ok, session}`.
  """
  def register_user(%{provider: provider, sub: sub} = identity, attrs) when is_binary(provider) and is_binary(sub) do
    context = Noizu.Context.system()
    provider_type = String.to_existing_atom(provider)
    provider_ref = @provider_map[provider_type].()
    {:ok, provider_id} = Therobotplans.Auth.Providers.Provider.id(provider_ref)
    email = identity[:email] |> to_string() |> String.trim() |> String.downcase()

    # Invite gate: required when the domain isn't allowlisted OR explicitly
    # requested by the caller.
    invite =
      if invite_token = attrs[:invite_token] do
        case Therobotplans.Organizations.find_active_invite_by_raw_token(invite_token) do
          {:ok, found} -> {:ok, found}
          error -> error
        end
      else
        if identity[:invite_required] or not domain_allowed?(email) do
          {:error, :invite_required}
        else
          {:ok, nil}
        end
      end

    with {:ok, _invite} <- invite,
         {:ok, user} <- create_sso_user(email, attrs, provider_type, attrs[:sub] || sub),
         _ <- ensure_sso_credential(user, provider_ref, provider_id, provider_type, %{email: email, sub: sub}, context),
         {:ok, session} <- create_sso_session(user, provider_type, context) do
      # If an invite was used, grant org membership + consume it (mirror AuthController.register).
      case invite do
        {:ok, %{organization_id: org_id} = used} when not is_nil(org_id) ->
          Therobotplans.Authz.ScopedMemberships.add_member("organization", org_id, user.id, "viewer")
          Therobotplans.Organizations.increment_invite_uses(used)

        {:ok, used} when not is_nil(used) ->
          Therobotplans.Organizations.increment_invite_uses(used)

        _ ->
          :ok
      end

      {:ok, session}
    end
  end

  # Create the user row for an SSO registration (verified on creation).
  defp create_sso_user(email, attrs, _provider_type, sub) do
    context = Noizu.Context.system()
    first = attrs[:first] || attrs[:name][:first] || ""
    last = attrs[:last] || attrs[:name][:last] || ""
    handle = email |> String.split("@") |> hd() |> String.replace(~r/[^a-z0-9_]/, "_")

    with {:ok, name} <-
           Therobotplans.EntityRepo.create(
             %Therobotplans.Versioned.Names.Name{first: first, last: last, time_stamp: Noizu.Entity.TimeStamp.now()},
             context
           ),
         {:ok, _name_ref} <- Noizu.EntityReference.Protocol.ref(name) do
      user_schema = %UserSchema{
        id: UUID.uuid4(),
        user_name: handle,
        handle: handle,
        name_id: name.id,
        email: email,
        status: :active,
        verified: true,
        flagged: false
      }

      # Idempotent on email (race-safe): re-fetch if it already existed.
      case Therobotplans.Repo.insert(user_schema, on_conflict: :nothing, conflict_target: :email) do
        {:ok, user} -> {:ok, user}
        {:error, _} ->
          case find_user_by_email(email) do
            {:ok, user} -> {:ok, user}
            :not_found -> {:error, :registration_failed}
          end
      end
    end
  end

  # Domain allowlist: true when the config is empty (open) or the email's
  # domain matches one of the allowlisted domains.
  defp domain_allowed?(email) do
    domains = Application.get_env(:therobotplans, :sso_allowed_domains, [])

    if domains == [] do
      true
    else
      case email |> String.split("@") |> List.last() do
        nil -> false
        domain -> String.downcase(domain) in Enum.map(domains, &String.downcase/1)
      end
    end
  end

  defp sso_subject(attrs), do: attrs[:sub] || attrs[:uid]

  defp find_user_by_email(email) do
    q = from u in UserSchema, where: u.email == ^email, where: u.status == :active, limit: 1

    case Therobotplans.Repo.one(q) do
      nil -> :not_found
      user -> {:ok, user}
    end
  end

  defp ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context) do
    fingerprint = sso_fingerprint(provider_type, attrs)

    q =
      from c in CredentialSchema,
        where: c.user_id == ^user.id,
        where: c.auth_provider_id == ^provider_id,
        where: c.status == :active,
        limit: 1

    case Therobotplans.Repo.one(q) do
      nil ->
        %Therobotplans.Users.Credentials.UserCredential{
          user: Therobotplans.Users.User.ref(user.id),
          auth_provider: provider_ref,
          status: :active,
          settings: sso_settings(provider_type, attrs),
          state: %{},
          fingerprint: fingerprint,
          time_stamp: Noizu.Entity.TimeStamp.now()
        }
        |> Therobotplans.EntityRepo.create(context)

      _existing ->
        :ok
    end
  end

  defp create_sso_session(user, provider_type, context) do
    user_ref = Therobotplans.Users.User.ref(user.id)

    %Therobotplans.Users.Sessions.UserSession{
      user: user_ref,
      status: :active,
      details: %{auth_method: to_string(provider_type)},
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Therobotplans.EntityRepo.create(context)
  end

  defp sso_settings(:saml, attrs), do: %{email: attrs[:email], name_id: attrs[:name_id]}
  defp sso_settings(provider_type, attrs), do: %{email: attrs[:email], sub: attrs[:sub] || attrs[:uid]}

  defp sso_fingerprint(:saml, attrs), do: "saml:#{attrs[:name_id]}"
  defp sso_fingerprint(provider_type, attrs), do: "#{provider_type}:#{attrs[:sub] || attrs[:uid]}"
end
