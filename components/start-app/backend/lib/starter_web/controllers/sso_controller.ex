defmodule StarterWeb.SSOController do
  use StarterWeb, :controller
  plug Ueberauth when action in [:oauth_request, :oauth_callback]

  alias Starter.Guardian
  alias Starter.Organizations

  # ⟦𓅔𓊲𓉬𓆧⟧ providers :: auto-generated pointer for public function providers
  def providers(conn, _params) do
    providers =
      []
      |> maybe_add(:oidc_enabled, "oidc")
      |> maybe_add(:google_enabled, "google")
      |> maybe_add(:facebook_enabled, "facebook")
      |> maybe_add(:github_enabled, "github")
      |> maybe_add(:linkedin_enabled, "linkedin")
      |> maybe_add(:saml_enabled, "saml")

    json(conn, %{
      providers: providers,
      domains: Starter.Auth.SSODomains.providers_map(),
      domain_policies: Starter.Auth.SSODomains.public_policies()
    })
  end

  # ── OIDC ──────────────────────────────────────────────────────

  # ⟦𓌞𓁽𓏆𓁊⟧ oidc_init :: auto-generated pointer for public function oidc_init
  def oidc_init(conn, _params) do
    config = oidc_config()
    {:ok, uri} = OpenIDConnect.authorization_uri(config, config.redirect_uri)
    redirect(conn, external: uri)
  end

  # ⟦𓊼𓏾𓌜𓄝⟧ oidc_callback :: auto-generated pointer for public function oidc_callback
  def oidc_callback(conn, %{"code" => code}) do
    config = oidc_config()

    with {:ok, tokens} <-
           OpenIDConnect.fetch_tokens(config, %{code: code, redirect_uri: config.redirect_uri}),
         {:ok, claims} <- OpenIDConnect.verify(config, tokens["id_token"]) do
      handle_sso_callback(conn, :oidc, %{
        email: claims["email"],
        name: %{first: claims["given_name"] || "", last: claims["family_name"] || ""},
        sub: claims["sub"]
      })
    else
      _ -> redirect_with_error(conn, "oidc_failed")
    end
  end

  def oidc_callback(conn, _params) do
    redirect_with_error(conn, "oidc_failed")
  end

  # ── Social OAuth (Ueberauth) ──────────────────────────────────

  # ⟦𓄗𓏙𓈃𓅖⟧ oauth_request :: auto-generated pointer for public function oauth_request
  def oauth_request(conn, _params) do
    conn
  end

  # ⟦𓇛𓌟𓇤𓂎⟧ oauth_callback :: auto-generated pointer for public function oauth_callback
  def oauth_callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    provider_type = auth.provider |> to_string() |> String.to_existing_atom()

    handle_sso_callback(conn, provider_type, %{
      email: auth.info.email,
      name: %{first: auth.info.first_name || "", last: auth.info.last_name || ""},
      uid: to_string(auth.uid),
      sub: to_string(auth.uid)
    })
  end

  def oauth_callback(%{assigns: %{ueberauth_failure: _}} = conn, %{"provider" => provider}) do
    redirect_with_error(conn, "#{provider}_failed")
  end

  # ── Code Exchange ────────────────────────────────────────────

  # ⟦𓆇𓎥𓎪𓎾⟧ exchange :: auto-generated pointer for public function exchange
  def exchange(conn, %{"code" => code}) do
    with {:ok, session_id} <- Starter.Auth.SSOCode.exchange(code),
         {:ok, session} <- Starter.Users.Sessions.get(session_id, Noizu.Context.system(), []),
         {:ok, access_token, _} <-
           Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, %{"jti" => refresh_jti}} <-
           Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
      Starter.Auth.TokenStore.store_refresh_jti(refresh_jti)
      user = resolve_user_from_session(session)
      orgs = Organizations.list_user_organizations(user.id)

      conn
      |> put_status(:ok)
      |> json(%{
        user: serialize_user(user),
        organizations: orgs,
        access_token: access_token,
        refresh_token: refresh_token
      })
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Invalid or expired SSO code"})
    end
  end

  # ── Helpers ──────────────────────────────────────────────────

  defp handle_sso_callback(conn, provider_type, attrs) do
    frontend_url = Application.get_env(:starter, :frontend_url, "http://localhost:3000")

    case Starter.Auth.SSO.authenticate_sso(provider_type, attrs) do
      {:ok, session} ->
        {:ok, code} = Starter.Auth.SSOCode.create(session.id)

        redirect(conn,
          external: "#{frontend_url}/auth/sso-callback?code=#{code}&provider=#{provider_type}"
        )

      {:error, :user_not_provisioned} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=not_provisioned")

      {:error, :sso_not_allowed} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_unavailable")

      {:error, _} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_failed")
    end
  end

  defp redirect_with_error(conn, error) do
    frontend_url = Application.get_env(:starter, :frontend_url, "http://localhost:3000")
    redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=#{error}")
  end

  defp oidc_config do
    :openid_connect
    |> Application.fetch_env!(:providers)
    |> Keyword.fetch!(:default)
    |> Map.new()
  end

  defp resolve_user_from_session(%Starter.Users.Sessions.UserSession{} = session) do
    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Starter.Users.get_user(id, Noizu.Context.system())
        user

      %Starter.Users.User{} = user ->
        user
    end
  end

  defp serialize_user(user) do
    %{
      id: user.id,
      email: user.email,
      user_name: user.user_name,
      handle: user.handle,
      mobile_phone: Map.get(user, :mobile_phone),
      status: user.status,
      verified: user.verified,
      profile_completed_at: Map.get(user, :profile_completed_at),
      profile_complete: !!Map.get(user, :profile_completed_at),
      requires_profile_completion: !Map.get(user, :profile_completed_at)
    }
  end

  defp maybe_add(list, flag, name) do
    if Application.get_env(:starter, flag), do: [name | list], else: list
  end
end
