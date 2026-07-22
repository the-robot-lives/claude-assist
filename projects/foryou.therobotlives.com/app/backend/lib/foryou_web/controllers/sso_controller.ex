defmodule ForyouWeb.SSOController do
  use ForyouWeb, :controller
  plug Ueberauth when action in [:oauth_request, :oauth_callback]

  alias Foryou.Guardian
  alias Foryou.Organizations

  def providers(conn, _params) do
    providers =
      []
      |> maybe_add(:oidc_enabled, "oidc")
      |> maybe_add(:google_enabled, "google")
      |> maybe_add(:facebook_enabled, "facebook")
      |> maybe_add(:github_enabled, "github")
      |> maybe_add(:linkedin_enabled, "linkedin")
      |> maybe_add(:saml_enabled, "saml")

    json(conn, %{providers: providers})
  end

  # ── OIDC ──────────────────────────────────────────────────────

  # openid_connect 1.0 takes an explicit config map (atom keys) at each call
  # site, read from :oidc_provider app env (set in runtime.exs).
  defp oidc_config do
    Application.get_env(:foryou, :oidc_provider) ||
      raise "OIDC provider not configured (set OIDC_CLIENT_ID/OIDC_ISSUER)"
  end

  def oidc_init(conn, _params) do
    config = oidc_config()
    {:ok, uri} = OpenIDConnect.authorization_uri(config, config.redirect_uri)
    redirect(conn, external: uri)
  end

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

  def oauth_request(conn, _params) do
    conn
  end

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

  def exchange(conn, %{"code" => code}) do
    with {:ok, session_id} <- Foryou.Auth.SSOCode.exchange(code),
         {:ok, session} <- Foryou.Users.Sessions.get_session(session_id, Noizu.Context.system()),
         {:ok, access_token, _} <- Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, %{"jti" => refresh_jti}} <- Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
      Foryou.Auth.TokenStore.store_refresh_jti(refresh_jti)
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
    frontend_url = Application.get_env(:foryou, :frontend_url, "http://localhost:3000")

    case Foryou.Auth.SSO.authenticate_sso(provider_type, attrs) do
      {:ok, session} ->
        {:ok, code} = Foryou.Auth.SSOCode.create(session.id)
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?code=#{code}&provider=#{provider_type}")

      {:error, :user_not_provisioned} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=not_provisioned")

      {:error, _} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_failed")
    end
  end

  defp redirect_with_error(conn, error) do
    frontend_url = Application.get_env(:foryou, :frontend_url, "http://localhost:3000")
    redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=#{error}")
  end

  defp resolve_user_from_session(%Foryou.Users.Sessions.UserSession{} = session) do
    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Foryou.Users.get_user(id, Noizu.Context.system())
        user
      %Foryou.Users.User{} = user -> user
    end
  end

  defp serialize_user(user) do
    %{
      id: user.id,
      email: user.email,
      user_name: user.user_name,
      handle: user.handle,
      status: user.status,
      verified: user.verified
    }
  end

  defp maybe_add(list, flag, name) do
    if Application.get_env(:foryou, flag), do: [name | list], else: list
  end
end
