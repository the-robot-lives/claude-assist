defmodule Therobotknows.Auth.SSO do
  alias Therobotknows.Schema.Users.User, as: UserSchema
  alias Therobotknows.Schema.Users.Credentials.UserCredential, as: CredentialSchema
  alias Therobotknows.Schema.Versioned.Names.Name
  import Ecto.Query, only: [from: 2]

  @provider_map %{
    oidc: &Therobotknows.Auth.Providers.oidc/0,
    saml: &Therobotknows.Auth.Providers.saml/0,
    google: &Therobotknows.Auth.Providers.google/0,
    facebook: &Therobotknows.Auth.Providers.facebook/0,
    github: &Therobotknows.Auth.Providers.github/0,
    linkedin: &Therobotknows.Auth.Providers.linkedin/0
  }

  def authenticate_sso(provider_type, %{email: email} = attrs) do
    context = Noizu.Context.system()
    email = email |> String.trim() |> String.downcase()

    provider_type = provider_type(provider_type)

    if provider_type && Therobotknows.Auth.SSODomains.sso_available?(email, provider_type) do
      provider_ref = provider_ref(provider_type)
      {:ok, provider_id} = Therobotknows.Auth.Providers.Provider.id(provider_ref)
      ensure_provider_row(provider_id, provider_type)

      case find_user_by_email(email) do
        {:ok, user} ->
          ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context)
          create_sso_session(user, provider_type, context)

        :not_found ->
          if Application.get_env(:therobotknows, :sso_require_invite, false) do
            {:error, :user_not_provisioned}
          else
            auto_provision_user(email, attrs, provider_ref, provider_id, provider_type, context)
          end
      end
    else
      {:error, :sso_not_allowed}
    end
  end

  # Providers.oidc/0 and friends delegate to Entity.ref/1, which returns
  # {:ok, {:ref, _, uuid}} — every other call site unwraps it before handing the
  # ref to Provider.id/1 (which only accepts a bare ref tuple).
  defp provider_ref(provider_type) do
    case @provider_map[provider_type].() do
      {:ok, provider_ref} -> provider_ref
      provider_ref -> provider_ref
    end
  end

  defp provider_type(value) when is_atom(value),
    do: if(Map.has_key?(@provider_map, value), do: value)

  defp provider_type(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.to_existing_atom()
    |> provider_type()
  rescue
    ArgumentError -> nil
  end

  defp provider_type(_), do: nil

  # Provider rows are referenced by deterministic UUID5 id but nothing seeds the
  # auth_providers table, so the first SSO login per provider would otherwise hit
  # user_credentials_auth_provider_id_fkey.
  defp ensure_provider_row(provider_id, provider_type) do
    title = provider_title(provider_type)

    Therobotknows.Repo.insert(
      %Therobotknows.Schema.Auth.Providers.Provider{
        id: provider_id,
        title: title,
        description: "#{title} single sign-on"
      },
      on_conflict: :nothing,
      conflict_target: :id
    )
  end

  defp provider_title(:oidc), do: "OIDC"
  defp provider_title(:saml), do: "SAML"
  defp provider_title(:github), do: "GitHub"
  defp provider_title(:linkedin), do: "LinkedIn"
  defp provider_title(type), do: type |> to_string() |> String.capitalize()

  defp find_user_by_email(email) do
    q = from u in UserSchema, where: u.email == ^email, where: u.status == :active, limit: 1

    case Therobotknows.Repo.one(q) do
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

    case Therobotknows.Repo.one(q) do
      nil ->
        %Therobotknows.Users.Credentials.UserCredential{
          user: {:ref, Therobotknows.Users.User, user.id},
          auth_provider: provider_ref,
          status: :active,
          settings: sso_settings(provider_type, attrs),
          state: %{},
          fingerprint: fingerprint,
          time_stamp: Noizu.Entity.TimeStamp.now()
        }
        |> Therobotknows.EntityRepo.create(context)

      _existing ->
        :ok
    end
  end

  defp create_sso_session(user, provider_type, context) do
    user_ref = {:ref, Therobotknows.Users.User, user.id}

    %Therobotknows.Users.Sessions.UserSession{
      user: user_ref,
      status: :active,
      details: %{auth_method: to_string(provider_type)},
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Therobotknows.EntityRepo.create(context)
  end

  defp auto_provision_user(email, attrs, provider_ref, provider_id, provider_type, context) do
    handle = email |> String.split("@") |> hd() |> String.replace(~r/[^a-z0-9_]/, "_")
    first = get_in(attrs, [:name, :first]) || attrs[:given_name] || handle
    last = get_in(attrs, [:name, :last]) || attrs[:family_name] || "User"

    # Insert the schema row directly. Versioned.Names.create/3 expects *attrs*,
    # not an %Entity{} — passing a struct makes its change/2 Enum.map over it and
    # raise Protocol.UndefinedError. TheRobotLearns does the same thing here.
    {:ok, name} =
      %Name{first: first, last: last}
      |> Therobotknows.Repo.insert()

    status = Therobotknows.Auth.SSODomains.registration_status(email, provider_type)

    user_schema = %UserSchema{
      id: UUID.uuid4(),
      user_name: handle,
      handle: handle,
      name_id: name.id,
      email: email,
      status: status,
      verified: true,
      flagged: false
    }

    {:ok, user} = Therobotknows.Repo.insert(user_schema, on_conflict: :nothing, conflict_target: :email)

    %Therobotknows.Users.Credentials.UserCredential{
      user: {:ref, Therobotknows.Users.User, user.id},
      auth_provider: provider_ref,
      status: :active,
      settings: sso_settings(provider_type, attrs),
      state: %{},
      fingerprint: sso_fingerprint(provider_type, attrs),
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Therobotknows.EntityRepo.create(context)

    # Unlike TheRobotLearns there is no post-session status gate here, so a
    # registration awaiting approval must not be handed a session.
    if status == :active do
      create_sso_session(user, provider_type, context)
    else
      {:error, :registration_pending}
    end
  end

  defp sso_settings(:saml, attrs), do: %{email: attrs[:email], name_id: attrs[:name_id]}
  defp sso_settings(provider_type, attrs), do: %{email: attrs[:email], sub: attrs[:sub] || attrs[:uid]}

  defp sso_fingerprint(:saml, attrs), do: "saml:#{attrs[:name_id]}"
  defp sso_fingerprint(provider_type, attrs), do: "#{provider_type}:#{attrs[:sub] || attrs[:uid]}"
end
