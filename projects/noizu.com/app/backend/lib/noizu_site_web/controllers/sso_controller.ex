defmodule NoizuSiteWeb.SSOController do
  use NoizuSiteWeb, :controller
  plug Ueberauth when action in [:oauth_request, :oauth_callback]

  alias NoizuSite.Guardian
  alias NoizuSite.Organizations

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

  def oidc_init(conn, _params) do
    config = oidc_config()

    # `state` and `nonce` were both absent, which left this flow open to
    # login-CSRF - an attacker completes a flow so the victim is silently signed
    # in AS the attacker - and to id_token replay. Both are verified in
    # `oidc_callback/2`. Ueberauth already does this for the social providers;
    # OIDC was the gap.
    state = random_token()
    nonce = random_token()

    {:ok, uri} =
      OpenIDConnect.authorization_uri(config, config.redirect_uri, %{
        state: state,
        nonce: nonce
      })

    conn
    |> put_session(:sso_state, state)
    |> put_session(:sso_nonce, nonce)
    |> redirect(external: uri)
  end

  def oidc_callback(conn, %{"code" => code} = params) do
    expected_state = get_session(conn, :sso_state)
    expected_nonce = get_session(conn, :sso_nonce)

    # State is checked before anything else, including reading the provider
    # config: a forged callback is rejected without a token request, a discovery
    # fetch, or any other work done on an attacker's behalf.
    with :ok <- verify_state(expected_state, params["state"]),
         config <- oidc_config(),
         {:ok, tokens} <-
           OpenIDConnect.fetch_tokens(config, %{code: code, redirect_uri: config.redirect_uri}),
         {:ok, claims} <- OpenIDConnect.verify(config, tokens["id_token"]),
         :ok <- verify_nonce(expected_nonce, claims["nonce"]) do
      handle_sso_callback(conn, :oidc, %{
        email: claims["email"],
        name: %{first: claims["given_name"] || "", last: claims["family_name"] || ""},
        sub: claims["sub"]
      })
    else
      {:error, :state_mismatch} -> redirect_with_error(conn, "state_mismatch")
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
    with {:ok, session_id} <- NoizuSite.Auth.SSOCode.exchange(code),
         {:ok, session} <- NoizuSite.Users.Sessions.get(session_id, Noizu.Context.system()),
         {:ok, access_token, _} <- Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, _} <- Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
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
    frontend_url = Application.get_env(:noizu_site, :frontend_url, "http://localhost:3000")

    case NoizuSite.Auth.SSO.authenticate_sso(provider_type, attrs) do
      {:ok, session} ->
        {:ok, code} = NoizuSite.Auth.SSOCode.create(session.id)
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?code=#{code}&provider=#{provider_type}")

      {:error, :user_not_provisioned} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=not_provisioned")

      {:error, _} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_failed")
    end
  end

  defp redirect_with_error(conn, error) do
    frontend_url = Application.get_env(:noizu_site, :frontend_url, "http://localhost:3000")
    redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=#{error}")
  end

  defp resolve_user_from_session(%NoizuSite.Users.Sessions.UserSession{} = session) do
    case session.user do
      {:ref, _, id} ->
        {:ok, user} = NoizuSite.Users.get_user(id, Noizu.Context.system())
        user
      %NoizuSite.Users.User{} = user -> user
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
    if Application.get_env(:noizu_site, flag), do: [name | list], else: list
  end

  # ── OIDC state / nonce ───────────────────────────────────────

  # A missing expected state is a failure, not a pass: it means the callback
  # arrived without a flow this browser started, which is exactly the forged
  # case. `secure_compare/2` because a timing oracle on the state is a slow way
  # to forge one.
  defp verify_state(nil, _received), do: {:error, :state_mismatch}
  defp verify_state(_expected, nil), do: {:error, :state_mismatch}

  defp verify_state(expected, received) do
    if Plug.Crypto.secure_compare(expected, received),
      do: :ok,
      else: {:error, :state_mismatch}
  end

  # A provider that omits the nonce it was given is not proof of replay, but a
  # provider that returns a DIFFERENT one is.
  defp verify_nonce(_expected, nil), do: :ok
  defp verify_nonce(nil, _received), do: :ok

  defp verify_nonce(expected, received) do
    if Plug.Crypto.secure_compare(expected, received), do: :ok, else: {:error, :nonce_mismatch}
  end

  defp random_token, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  # openid_connect 1.x takes the provider config as a map argument. The 0.2.x
  # API this module used to call - `authorization_uri(:default)` and friends -
  # does not exist in 1.0.1, so `/auth/oidc` raised UndefinedFunctionError on
  # every request and OIDC sign-in has never worked here.
  defp oidc_config do
    :openid_connect
    |> Application.fetch_env!(:providers)
    |> Keyword.fetch!(:default)
    |> Map.new()
  end
end
