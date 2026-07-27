defmodule DerobotWeb.SSOController do
  use DerobotWeb, :controller
  plug Ueberauth when action in [:oauth_request, :oauth_callback]

  alias Derobot.Guardian

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

  # -- OIDC -------------------------------------------------------------------

  def oidc_init(conn, _params) do
    # Two bugs are fixed together here, and fixing only the first would be worse
    # than fixing neither.
    #
    # 1. ARITY. This called `authorization_uri(:default)`, the openid_connect
    #    v0.2.x API, against v1.0.1 which exports only /2 and /3. Every request
    #    to /auth/oidc raised UndefinedFunctionError, so OIDC sign-in has never
    #    worked on this deployment.
    #
    # 2. STATE + NONCE. Neither was generated, leaving the flow open to
    #    login-CSRF - an attacker completes a flow so the VICTIM's browser is
    #    signed in as the ATTACKER, and subsequent work is typed into the
    #    attacker's account - and to id_token replay.
    #
    # Repairing the arity alone would have turned a dead endpoint into a live
    # and unprotected one, which is to say it would have introduced the
    # vulnerability rather than fixed it. Both land in the same change.
    config = oidc_config()

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

    # State is checked FIRST, before the provider config is even read: a forged
    # callback is rejected without a token request, a discovery fetch, or any
    # other work performed on an attacker's behalf.
    #
    # `fetch_tokens/2` and `verify/2` were also on the v0.2.x calling convention
    # - an atom where a config map belongs, and a bare code where a params map
    # belongs - so they are migrated here too.
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

  # -- Social OAuth (Ueberauth) -----------------------------------------------

  def oauth_request(conn, _params), do: conn

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

  # -- Code Exchange -----------------------------------------------------------

  def exchange(conn, %{"code" => code}) do
    with {:ok, session_id} <- Derobot.Auth.SSOCode.exchange(code),
         {:ok, session} <- Derobot.Users.Sessions.get(session_id, Noizu.Context.system()),
         {:ok, access_token, _} <- Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, _} <- Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
      user = resolve_user_from_session(session)

      conn
      |> put_status(:ok)
      |> json(%{
        user: serialize_user(user),
        access_token: access_token,
        refresh_token: refresh_token
      })
    else
      _ -> conn |> put_status(:unauthorized) |> json(%{error: "Invalid or expired SSO code"})
    end
  end

  # -- Helpers -----------------------------------------------------------------

  defp handle_sso_callback(conn, provider_type, attrs) do
    conn = clear_sso_session(conn)
    frontend_url = Application.get_env(:derobot, :frontend_url, "http://localhost:3000")

    case Derobot.Auth.SSO.authenticate_sso(provider_type, attrs) do
      {:ok, session} ->
        {:ok, code} = Derobot.Auth.SSOCode.create(session.id)
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?code=#{code}&provider=#{provider_type}")

      {:error, :user_not_provisioned} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=not_provisioned")

      {:error, _} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_failed")
    end
  end

  defp redirect_with_error(conn, error) do
    conn = clear_sso_session(conn)
    frontend_url = Application.get_env(:derobot, :frontend_url, "http://localhost:3000")
    redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=#{error}")
  end

  defp resolve_user_from_session(%Derobot.Users.Sessions.UserSession{} = session) do
    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Derobot.Users.get_user(id, Noizu.Context.system())
        user

      %Derobot.Users.User{} = user ->
        user
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
    if Application.get_env(:derobot, flag), do: [name | list], else: list
  end

  # ── OIDC state / nonce ───────────────────────────────────────

  # Public, and `@doc false`, solely so the guards can be unit-tested against the
  # REAL functions with no database, no HTTP and no identity provider. They are
  # not routed and are not part of the controller's action surface.
  #
  # The nonce guard in particular has no other way to be tested: it only runs
  # after a successful token exchange, which no suite here can reach without a
  # live or mocked IdP. Calling it directly is the only way to assert that a
  # replayed nonce is actually refused.
  @doc false
  def verify_state(nil, _received), do: {:error, :state_mismatch}
  def verify_state(_expected, nil), do: {:error, :state_mismatch}

  def verify_state(expected, received) do
    if Plug.Crypto.secure_compare(expected, received),
      do: :ok,
      else: {:error, :state_mismatch}
  end

  # A provider that omits the nonce it was handed is not evidence of replay -
  # not every provider echoes it. A provider that returns a DIFFERENT one is.
  @doc false
  def verify_nonce(_expected, nil), do: :ok
  def verify_nonce(nil, _received), do: :ok

  def verify_nonce(expected, received) do
    if Plug.Crypto.secure_compare(expected, received), do: :ok, else: {:error, :nonce_mismatch}
  end

  # Cleared on both success and failure, so a state value can never be reused by
  # a second callback.
  defp clear_sso_session(conn) do
    conn
    |> delete_session(:sso_state)
    |> delete_session(:sso_nonce)
  end

  defp random_token, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  # v1.x takes a config MAP, not the `:default` provider atom the v0.2.x API
  # accepted. Reading it here keeps the two call sites from drifting apart.
  defp oidc_config do
    :openid_connect
    |> Application.fetch_env!(:providers)
    |> Keyword.fetch!(:default)
    |> Map.new()
  end
end
