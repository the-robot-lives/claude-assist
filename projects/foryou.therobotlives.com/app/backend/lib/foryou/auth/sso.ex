defmodule Foryou.Auth.SSO do
  alias Foryou.Schema.Users.User, as: UserSchema
  alias Foryou.Schema.Users.Credentials.UserCredential, as: CredentialSchema
  alias Foryou.Schema.Users.Sessions.UserSession, as: SessionSchema
  alias Foryou.Schema.Versioned.Names.Name
  import Ecto.Query, only: [from: 2]

  @provider_map %{
    oidc: &Foryou.Auth.Providers.oidc/0,
    saml: &Foryou.Auth.Providers.saml/0,
    google: &Foryou.Auth.Providers.google/0,
    facebook: &Foryou.Auth.Providers.facebook/0,
    github: &Foryou.Auth.Providers.github/0,
    linkedin: &Foryou.Auth.Providers.linkedin/0
  }

  def authenticate_sso(provider_type, %{email: email} = attrs) do
    context = Noizu.Context.system()
    email = email |> String.trim() |> String.downcase()
    provider_ref = unwrap_ref(@provider_map[provider_type].())
    provider_id = provider_ref_id(provider_ref)

    case find_user_by_email(email) do
      {:ok, user} ->
        ensure_sso_credential(user, provider_ref, provider_id, provider_type, attrs, context)
        create_sso_session(user, provider_type, context)

      :not_found ->
        if Application.get_env(:foryou, :sso_require_invite, false) do
          {:error, :user_not_provisioned}
        else
          auto_provision_user(email, attrs, provider_ref, provider_id, provider_type, context)
        end
    end
  end

  defp unwrap_ref({:ok, ref}), do: ref
  defp unwrap_ref(ref), do: ref

  # provider_ref is a Noizu entity ref ({:ref, module, uuid}); extract the UUID
  # directly. Provider.id/1 returns {:error, {:unsupported, _}} for a wrapped
  # ref, so we don't route through it.
  defp provider_ref_id({:ref, _module, id}), do: id
  defp provider_ref_id(id) when is_binary(id), do: id

  defp find_user_by_email(email) do
    q = from u in UserSchema, where: u.email == ^email, where: u.status == :active, limit: 1

    case Foryou.Repo.one(q) do
      nil -> :not_found
      user -> {:ok, user}
    end
  end

  # Raw insert of the credential schema (mirrors tobornalp/NPL) — same reason as
  # the Name insert: entity create/change expects an attrs map, not a struct.
  defp ensure_sso_credential(user, _provider_ref, provider_id, provider_type, attrs, _context) do
    fingerprint = sso_fingerprint(provider_type, attrs)

    q =
      from c in CredentialSchema,
        where: c.user_id == ^user.id,
        where: c.auth_provider_id == ^provider_id,
        where: c.status == :active,
        limit: 1

    case Foryou.Repo.one(q) do
      nil ->
        Foryou.Repo.insert!(%CredentialSchema{
          user_id: user.id,
          auth_provider_id: provider_id,
          status: :active,
          settings: sso_settings(provider_type, attrs),
          state: %{},
          fingerprint: fingerprint
        })

      _existing ->
        :ok
    end
  end

  # Raw insert of the session schema (mirrors tobornalp/NPL) — same reason as
  # the Name insert. The Redis-backed SSOCode flow only needs the row's id.
  defp create_sso_session(user, provider_type, _context) do
    Foryou.Repo.insert(%SessionSchema{
      user_id: user.id,
      status: :active,
      details: %{auth_method: to_string(provider_type)}
    })
  end

  defp auto_provision_user(email, attrs, _provider_ref, provider_id, provider_type, context) do
    first = attrs[:name][:first] || ""
    last = attrs[:name][:last] || ""
    handle = email |> String.split("@") |> hd() |> String.replace(~r/[^a-z0-9_]/, "_")

    # Raw insert of the versioned-name schema (mirrors tobornalp/NPL). The
    # entity Names.create/change expects an attrs *map*, not a %Name{} struct —
    # passing a struct makes change/2 call Enum.map on it → Protocol.UndefinedError.
    name = Foryou.Repo.insert!(%Name{first: first, last: last, middle: []})

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

    {:ok, user} = Foryou.Repo.insert(user_schema, on_conflict: :nothing, conflict_target: :email)

    Foryou.Repo.insert!(%CredentialSchema{
      user_id: user.id,
      auth_provider_id: provider_id,
      status: :active,
      settings: sso_settings(provider_type, attrs),
      state: %{},
      fingerprint: sso_fingerprint(provider_type, attrs)
    })

    create_sso_session(user, provider_type, context)
  end

  defp sso_settings(:saml, attrs), do: %{email: attrs[:email], name_id: attrs[:name_id]}
  defp sso_settings(provider_type, attrs), do: %{email: attrs[:email], sub: attrs[:sub] || attrs[:uid]}

  defp sso_fingerprint(:saml, attrs), do: "saml:#{attrs[:name_id]}"
  defp sso_fingerprint(provider_type, attrs), do: "#{provider_type}:#{attrs[:sub] || attrs[:uid]}"
end
