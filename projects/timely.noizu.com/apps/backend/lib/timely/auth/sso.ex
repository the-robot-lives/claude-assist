defmodule Timely.Auth.SSO do
  alias Timely.Schema.Users.User, as: UserSchema
  alias Timely.Schema.Users.Credentials.UserCredential, as: CredentialSchema
  import Ecto.Query, only: [from: 2]

  @provider_map %{
    oidc: &Timely.Auth.Providers.oidc/0,
    saml: &Timely.Auth.Providers.saml/0,
    google: &Timely.Auth.Providers.google/0,
    facebook: &Timely.Auth.Providers.facebook/0,
    github: &Timely.Auth.Providers.github/0,
    linkedin: &Timely.Auth.Providers.linkedin/0
  }

  # ⟦𓅷𓊹𓀡𓐓⟧ authenticate_sso :: auto-generated pointer for public function authenticate_sso
  def authenticate_sso(provider_type, %{email: email} = attrs) do
    context = Noizu.Context.system()
    email = email |> String.trim() |> String.downcase()
    provider_type = provider_type(provider_type)

    with provider_type when not is_nil(provider_type) <- provider_type,
         true <- Timely.Auth.SSODomains.sso_available?(email, provider_type) do
      provider_ref = provider_ref(provider_type)
      {:ok, provider_id} = Timely.Auth.Providers.Provider.id(provider_ref)

      case find_user_by_email(email) do
        {:ok, user} ->
          ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context)
          create_sso_session(user, provider_type, context)

        :not_found ->
          auto_provision_user(email, attrs, provider_ref, provider_id, provider_type, context)
      end
    else
      _ -> {:error, :sso_not_allowed}
    end
  end

  defp find_user_by_email(email) do
    q = from u in UserSchema, where: u.email == ^email, where: u.status != :deleted, limit: 1

    case Timely.Repo.one(q) do
      nil -> :not_found
      user -> {:ok, user}
    end
  end

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

  defp ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context) do
    user_ref = {:ref, Timely.Users.User, user.id}
    fingerprint = sso_fingerprint(provider_type, attrs)

    q =
      from c in CredentialSchema,
        where: c.user_id == ^user.id,
        where: c.auth_provider_id == ^provider_id,
        where: c.status == :active,
        limit: 1

    case Timely.Repo.one(q) do
      nil ->
        %Timely.Users.Credentials.UserCredential{
          user: user_ref,
          auth_provider: provider_ref,
          status: :active,
          settings: sso_settings(provider_type, attrs),
          state: %{},
          fingerprint: fingerprint,
          time_stamp: Noizu.Entity.TimeStamp.now()
        }
        |> Timely.EntityRepo.create(context)

      _existing ->
        :ok
    end
  end

  defp create_sso_session(user, provider_type, context) do
    user_ref = {:ref, Timely.Users.User, user.id}

    %Timely.Users.Sessions.UserSession{
      user: user_ref,
      status: :active,
      details: %{auth_method: to_string(provider_type)},
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Timely.EntityRepo.create(context)
  end

  defp auto_provision_user(email, attrs, provider_ref, _provider_id, provider_type, context) do
    handle = email |> String.split("@") |> hd() |> String.replace(~r/[^a-z0-9_]/, "_")
    first = get_in(attrs, [:name, :first]) || attrs[:given_name] || handle
    last = get_in(attrs, [:name, :last]) || attrs[:family_name] || "User"

    {:ok, name} =
      %Timely.Schema.Versioned.Names.Name{
        first: first,
        last: last
      }
      |> Timely.Repo.insert()

    approved_at = auto_approved_at(email, provider_type)

    user_schema = %UserSchema{
      id: UUID.uuid4(),
      user_name: handle,
      handle: handle,
      name_id: name.id,
      email: email,
      status: Timely.Auth.SSODomains.registration_status(email, provider_type),
      verified: true,
      flagged: false,
      approved_at: approved_at,
      # Authentik already collected identity — allow landing on /app dashboard
      profile_completed_at: if(approved_at, do: DateTime.utc_now(), else: nil)
    }

    {:ok, user} = Timely.Repo.insert(user_schema, on_conflict: :nothing, conflict_target: :email)

    %Timely.Users.Credentials.UserCredential{
      user: {:ref, Timely.Users.User, user.id},
      auth_provider: provider_ref,
      status: :active,
      settings: sso_settings(provider_type, attrs),
      state: %{},
      fingerprint: sso_fingerprint(provider_type, attrs),
      time_stamp: Noizu.Entity.TimeStamp.now()
    }
    |> Timely.EntityRepo.create(context)

    create_sso_session(user, provider_type, context)
  end

  defp auto_approved_at(email, provider_type) do
    if Timely.Auth.SSODomains.auto_approve?(email, provider_type), do: DateTime.utc_now()
  end

  defp sso_settings(:saml, attrs), do: %{email: attrs[:email], name_id: attrs[:name_id]}

  defp sso_settings(_provider_type, attrs),
    do: %{email: attrs[:email], sub: attrs[:sub] || attrs[:uid]}

  defp sso_fingerprint(:saml, attrs), do: "saml:#{attrs[:name_id]}"
  defp sso_fingerprint(provider_type, attrs), do: "#{provider_type}:#{attrs[:sub] || attrs[:uid]}"
end
