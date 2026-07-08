defmodule Therobotplans.Auth.SSO do
  alias Therobotplans.Schema.Users.User, as: UserSchema
  alias Therobotplans.Schema.Users.Credentials.UserCredential, as: CredentialSchema
  alias Therobotplans.Schema.Users.Sessions.UserSession, as: SessionSchema
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
    provider_ref = unwrap_ref(@provider_map[provider_type].())
    provider_id = provider_ref_id(provider_ref)

    case find_user_by_email(email) do
      {:ok, user} ->
        # Returning user — link credential if missing, issue a session (login).
        ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context)
        create_sso_session(user, provider_type)

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
    provider_ref = unwrap_ref(@provider_map[provider_type].())
    provider_id = provider_ref_id(provider_ref)
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
        # `||` not `or`: identity[:invite_required] is nil (not false) for
        # allowlisted domains, and `or` requires a boolean left operand.
        if identity[:invite_required] || not domain_allowed?(email) do
          {:error, :invite_required}
        else
          {:ok, nil}
        end
      end

    with {:ok, _invite} <- invite,
         {:ok, user} <- create_sso_user(email, attrs, provider_type, attrs[:sub] || sub),
         _ <- ensure_sso_credential(user, provider_ref, provider_id, provider_type, %{email: email, sub: sub}, context),
         {:ok, session} <- create_sso_session(user, provider_type) do
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
  defp create_sso_user(email, attrs, _provider_type, _sub) do
    first = attrs[:first] || attrs[:name][:first] || ""
    last = attrs[:last] || attrs[:name][:last] || ""
    handle = email |> String.split("@") |> hd() |> String.replace(~r/[^a-z0-9_]/, "_")

    # Raw insert of the versioned-name schema (mirrors NPL). The entity
    # Names.create/change expects an attrs *map*, not a %Name{} struct —
    # passing a struct makes change/2 call Enum.map on it → Protocol.UndefinedError.
    name = Therobotplans.Repo.insert!(%Name{first: first, last: last, middle: []})

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
      {:ok, user} ->
        {:ok, user}

      {:error, _} ->
        case find_user_by_email(email) do
          {:ok, user} -> {:ok, user}
          :not_found -> {:error, :registration_failed}
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

  # Auth.Providers.*/0 return Entity.ref/1 results, which are wrapped as
  # {:ok, {:ref, module, uuid}}. Normalize to the bare {:ref, module, uuid} so
  # downstream credential creation gets a real ref (and Provider.id/1 doesn't
  # choke on the {:ok, _} wrapper — the source of the /auth/oidc/callback 500).
  defp unwrap_ref({:ok, ref}), do: ref
  defp unwrap_ref(ref), do: ref

  # provider_ref is a Noizu entity ref ({:ref, module, uuid}); extract the UUID
  # directly. Provider.id/1 returns {:error, {:unsupported, _}} for a wrapped
  # ref, so we don't route through it.
  defp provider_ref_id({:ref, _module, id}), do: id
  defp provider_ref_id(id) when is_binary(id), do: id

  defp sso_subject(attrs), do: attrs[:sub] || attrs[:uid]

  defp find_user_by_email(email) do
    q = from u in UserSchema, where: u.email == ^email, where: u.status == :active, limit: 1

    case Therobotplans.Repo.one(q) do
      nil -> :not_found
      user -> {:ok, user}
    end
  end

  # Raw insert of the credential schema (mirrors NPL). Same reason as
  # create_sso_user: the entity create/change expects an attrs map, and feeding
  # it a %UserCredential{} struct crashes change/2 with Protocol.UndefinedError.
  defp ensure_sso_credential(user, _provider_ref, provider_id, provider_type, attrs, _context) do
    fingerprint = sso_fingerprint(provider_type, attrs)

    exists =
      from(c in CredentialSchema,
        where: c.user_id == ^user.id,
        where: c.auth_provider_id == ^provider_id,
        where: c.status == :active,
        limit: 1
      )
      |> Therobotplans.Repo.one()

    if is_nil(exists) do
      Therobotplans.Repo.insert!(%CredentialSchema{
        user_id: user.id,
        auth_provider_id: provider_id,
        status: :active,
        settings: sso_settings(provider_type, attrs),
        state: %{},
        fingerprint: fingerprint
      })
    end

    :ok
  end

  # Returns {:ok, session_schema}. The session carries a one-time claim_code that
  # the controller/SAML handler puts in the redirect; the SPA exchanges it via
  # claim_session/1. Replaces the Redis-backed Therobotplans.Auth.SSOCode.
  defp create_sso_session(user, provider_type) do
    claim_code = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    expires = DateTime.utc_now() |> DateTime.add(60, :second)

    Therobotplans.Repo.insert(%SessionSchema{
      user_id: user.id,
      status: :active,
      details: %{auth_method: to_string(provider_type)},
      claim_code: claim_code,
      claim_code_expires_at: expires
    })
  end

  @doc """
  Atomically claim a session by its one-time code (single-use). The UPDATE
  matches on claim_code and clears it in the same statement, so concurrent
  (e.g. React StrictMode-doubled) calls can't both succeed.
  """
  def claim_session(claim_code) when is_binary(claim_code) do
    now = DateTime.utc_now()

    {count, rows} =
      from(s in SessionSchema,
        where: s.claim_code == ^claim_code,
        where: s.status == :active,
        where: s.claim_code_expires_at > ^now,
        select: s
      )
      |> Therobotplans.Repo.update_all(set: [claim_code: nil])

    case {count, rows} do
      {1, [session]} -> {:ok, session}
      _ -> {:error, :invalid_code}
    end
  end

  def claim_session(_), do: {:error, :invalid_code}

  defp sso_settings(:saml, attrs), do: %{email: attrs[:email], name_id: attrs[:name_id]}
  defp sso_settings(provider_type, attrs), do: %{email: attrs[:email], sub: attrs[:sub] || attrs[:uid]}

  defp sso_fingerprint(:saml, attrs), do: "saml:#{attrs[:name_id]}"
  defp sso_fingerprint(provider_type, attrs), do: "#{provider_type}:#{attrs[:sub] || attrs[:uid]}"
end
