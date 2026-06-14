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
    provider_ref = @provider_map[provider_type].()
    {:ok, provider_id} = Therobotknows.Auth.Providers.Provider.id(provider_ref)

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
  end

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
          user: Therobotknows.Users.User.ref(user.id),
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
    user_ref = Therobotknows.Users.User.ref(user.id)

    %Therobotknows.Users.Sessions.UserSession{
      user: user_ref,
      status: :active,
      details: %{auth_method: to_string(provider_type)},
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Therobotknows.EntityRepo.create(context)
  end

  defp auto_provision_user(email, attrs, provider_ref, provider_id, provider_type, context) do
    first = attrs[:name][:first] || ""
    last = attrs[:name][:last] || ""
    handle = email |> String.split("@") |> hd() |> String.replace(~r/[^a-z0-9_]/, "_")

    {:ok, name} =
      Therobotknows.EntityRepo.create(
        %Therobotknows.Versioned.Names.Name{first: first, last: last, time_stamp: Noizu.Entity.TimeStamp.now()},
        context
      )

    {:ok, name_ref} = Noizu.EntityReference.Protocol.ref(name)

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

    {:ok, user} = Therobotknows.Repo.insert(user_schema, on_conflict: :nothing, conflict_target: :email)

    %Therobotknows.Users.Credentials.UserCredential{
      user: Therobotknows.Users.User.ref(user.id),
      auth_provider: provider_ref,
      status: :active,
      settings: sso_settings(provider_type, attrs),
      state: %{},
      fingerprint: sso_fingerprint(provider_type, attrs),
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Therobotknows.EntityRepo.create(context)

    create_sso_session(user, provider_type, context)
  end

  defp sso_settings(:saml, attrs), do: %{email: attrs[:email], name_id: attrs[:name_id]}
  defp sso_settings(provider_type, attrs), do: %{email: attrs[:email], sub: attrs[:sub] || attrs[:uid]}

  defp sso_fingerprint(:saml, attrs), do: "saml:#{attrs[:name_id]}"
  defp sso_fingerprint(provider_type, attrs), do: "#{provider_type}:#{attrs[:sub] || attrs[:uid]}"
end
