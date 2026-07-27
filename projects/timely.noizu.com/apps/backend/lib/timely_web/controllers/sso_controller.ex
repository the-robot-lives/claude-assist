defmodule TimelyWeb.SSOController do
  use TimelyWeb, :controller

  # MUST come before the Ueberauth plug. Ueberauth's request phase redirects to
  # the provider and halts, so the action body never runs for `:oauth_request` -
  # anything that has to be recorded before the user leaves has to be recorded
  # here, not in the action.
  plug :capture_sso_flow when action in [:oidc_init, :oauth_request]
  plug Ueberauth when action in [:oauth_request, :oauth_callback]

  alias Timely.Auth.SSOCode
  alias Timely.Auth.SSORedirects
  alias Timely.Guardian
  alias Timely.Organizations

  # ⟦𓁔𓉞𓃍𓎵⟧ providers :: auto-generated pointer for public function providers
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
      domains: Timely.Auth.SSODomains.providers_map(),
      domain_policies: Timely.Auth.SSODomains.public_policies()
    })
  end

  # ── OIDC ──────────────────────────────────────────────────────

  # ⟦𓏣𓆽𓌓𓉹⟧ oidc_init :: auto-generated pointer for public function oidc_init
  def oidc_init(conn, _params) do
    config = oidc_config()

    # `state` and `nonce` were both absent before this change, leaving the OIDC
    # flow open to login-CSRF - an attacker completing a flow so the victim is
    # signed in as the attacker - and to id_token replay. Both are checked in
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

  # ⟦𓁘𓆾𓅡𓃞⟧ oidc_callback :: auto-generated pointer for public function oidc_callback
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

  # ⟦𓐧𓆞𓊱𓅩⟧ oauth_request :: auto-generated pointer for public function oauth_request
  def oauth_request(conn, _params) do
    # Unreachable in practice: the Ueberauth plug redirects to the provider and
    # halts before the action runs. Kept because a strategy that declines to
    # handle the request falls through to here.
    conn
  end

  # ⟦𓅂𓁤𓈬𓊔⟧ oauth_callback :: auto-generated pointer for public function oauth_callback
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

  # ⟦𓏙𓅴𓅧𓂴⟧ exchange :: auto-generated pointer for public function exchange
  def exchange(conn, %{"code" => code} = params) do
    with {:ok, session_id} <-
           SSOCode.exchange(code, code_verifier: params["code_verifier"]),
         {:ok, session} <- Timely.Users.Sessions.get(session_id, Noizu.Context.system(), []),
         {:ok, access_token, _} <-
           Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, %{"jti" => refresh_jti}} <-
           Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
      Timely.Auth.TokenStore.store_refresh_jti(refresh_jti)
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
    case Timely.Auth.SSO.authenticate_sso(provider_type, attrs) do
      {:ok, session} ->
        {:ok, code} =
          SSOCode.create(session.id, code_challenge: get_session(conn, :sso_challenge))

        conn
        |> clear_sso_session()
        |> redirect_to_target(%{"code" => code, "provider" => to_string(provider_type)})

      {:error, :user_not_provisioned} ->
        redirect_with_error(conn, "not_provisioned")

      {:error, :sso_not_allowed} ->
        redirect_with_error(conn, "sso_unavailable")

      {:error, _} ->
        redirect_with_error(conn, "sso_failed")
    end
  end

  defp redirect_with_error(conn, error) do
    # Errors go to the SAME target as success. A native flow that reports an
    # error to the web page leaves ASWebAuthenticationSession open with nothing
    # to return to, and the app hangs exactly as it does on the missing-scheme
    # bug this replaces.
    conn
    |> clear_sso_session()
    |> redirect_to_target(%{"error" => to_string(error)})
  end

  # The redirect target was validated against the allow-list before the user
  # left for the provider, and is re-validated here: the session is signed, but
  # re-checking costs nothing and means a change to the allow-list takes effect
  # for flows already in progress rather than honouring a target that has since
  # been revoked.
  defp redirect_to_target(conn, params) do
    target =
      case SSORedirects.validate(get_session(conn, :sso_redirect)) do
        {:ok, validated} -> validated
        {:error, _} -> SSORedirects.default()
      end

    url = SSORedirects.with_params(target, params)

    if SSORedirects.native?(target) do
      # `external:` is required for a custom scheme; Phoenix refuses to treat it
      # as a same-origin path.
      redirect(conn, external: url)
    else
      redirect(conn, to: url)
    end
  end

  defp clear_sso_session(conn) do
    conn
    |> delete_session(:sso_state)
    |> delete_session(:sso_nonce)
  end

  # Records where this flow should hand back, and the PKCE challenge that will
  # bind the resulting code, before the user is sent to the provider. Both live
  # in the signed session cookie rather than travelling through the provider, so
  # neither can be tampered with in flight.
  defp capture_sso_flow(conn, _opts) do
    case SSORedirects.validate(conn.params["redirect_uri"]) do
      {:error, :redirect_not_allowed} ->
        # Refused loudly rather than falling back to the web default. A native
        # client that mistyped its scheme would otherwise get a flow that
        # "succeeds" into a web page it cannot see, and hang.
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "redirect_not_allowed",
          message: "redirect_uri is not registered for this deployment"
        })
        |> halt()

      {:ok, target} ->
        challenge = conn.params["code_challenge"]

        cond do
          is_nil(challenge) ->
            put_session(conn, :sso_redirect, target)

          SSOCode.valid_challenge?(challenge) and
              conn.params["code_challenge_method"] in [nil, "S256"] ->
            conn
            |> put_session(:sso_redirect, target)
            |> put_session(:sso_challenge, challenge)

          true ->
            conn
            |> put_status(:bad_request)
            |> json(%{
              error: "invalid_code_challenge",
              message: "code_challenge must be 43-128 base64url characters, method S256"
            })
            |> halt()
        end
    end
  end

  # Public (not `defp`) so a unit test can exercise the actual guard directly -
  # `nonce` is only checked after a real token exchange, which no test suite
  # here can fake without a live/mocked IdP, so a unit test against the real
  # function is the only way to assert the rejection instead of just its
  # presence. Not part of the router surface; `@doc false` keeps it out of
  # generated docs.
  @doc false
  def verify_state(nil, _received), do: {:error, :state_mismatch}
  def verify_state(_expected, nil), do: {:error, :state_mismatch}

  def verify_state(expected, received) do
    if Plug.Crypto.secure_compare(expected, received),
      do: :ok,
      else: {:error, :state_mismatch}
  end

  # A provider that omits the nonce it was given is not proof of replay, but a
  # provider that returns a DIFFERENT one is.
  @doc false
  def verify_nonce(_expected, nil), do: :ok
  def verify_nonce(nil, _received), do: :ok

  def verify_nonce(expected, received) do
    if Plug.Crypto.secure_compare(expected, received), do: :ok, else: {:error, :nonce_mismatch}
  end

  defp random_token, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  defp oidc_config do
    :openid_connect
    |> Application.fetch_env!(:providers)
    |> Keyword.fetch!(:default)
    |> Map.new()
  end

  defp resolve_user_from_session(%Timely.Users.Sessions.UserSession{} = session) do
    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Timely.Users.get_user(id, Noizu.Context.system())
        user

      %Timely.Users.User{} = user ->
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
    if Application.get_env(:timely, flag), do: [name | list], else: list
  end
end
