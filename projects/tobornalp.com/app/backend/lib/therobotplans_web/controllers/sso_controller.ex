defmodule TherobotplansWeb.SSOController do
  use TherobotplansWeb, :controller
  plug Ueberauth when action in [:oauth_request, :oauth_callback]

  alias Therobotplans.Guardian
  alias Therobotplans.Organizations

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
      domains: Therobotplans.Auth.SSODomains.providers_map(),
      domain_policies: Therobotplans.Auth.SSODomains.public_policies()
    })
  end

  # ── OIDC ──────────────────────────────────────────────────────

  # openid_connect 1.0 takes an explicit config map (atom keys) at each call
  # site, read from :oidc_provider app env (set in runtime.exs).
  defp oidc_config do
    Application.get_env(:therobotplans, :oidc_provider) ||
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
    with {:ok, claimed} <- Therobotplans.Auth.SSO.claim_session(code),
         {:ok, session} <-
           Therobotplans.Users.Sessions.get(claimed.id, Noizu.Context.system(), []),
         {:ok, access_token, _} <-
           Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, %{"jti" => refresh_jti}} <-
           Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
      # Register the refresh JTI so later /auth/refresh calls validate (mirrors register/2).
      Therobotplans.Auth.TokenStore.store_refresh_jti(refresh_jti)

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
    frontend_url = Application.get_env(:therobotplans, :frontend_url, "http://localhost:3000")

    case Therobotplans.Auth.SSO.authenticate_sso(provider_type, attrs) do
      {:ok, session} ->
        # session.claim_code is the one-time hand-off code (DB-backed, no Redis).
        redirect(conn,
          external:
            "#{frontend_url}/auth/sso-callback?code=#{session.claim_code}&provider=#{provider_type}"
        )

      {:registration_required, identity} ->
        # Brand-new SSO identity: sign a short-lived token carrying the verified
        # identity, redirect to the register form to collect name (+ invite).
        token = Therobotplans.Auth.RegistrationToken.sign(identity)
        invite_flag = if identity[:invite_required], do: "&invite=1", else: ""
        redirect(conn, external: "#{frontend_url}/auth/register?token=#{token}#{invite_flag}")

      {:error, :sso_not_allowed} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_unavailable")

      {:error, _} ->
        redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=sso_failed")
    end
  end

  # ── SSO Registration ──────────────────────────────────────────

  # Prefill: peek at the pending identity so the register form can show the
  # verified email and whether an invite is required.
  def registration(conn, %{"token" => token}) do
    case Therobotplans.Auth.RegistrationToken.verify(token) do
      {:ok, identity} ->
        json(conn, %{
          email: identity[:email],
          provider: identity[:provider],
          invite_required: identity[:invite_required] == true,
          auto_approve: identity[:auto_approve] == true
        })

      _ ->
        conn |> put_status(:not_found) |> json(%{error: "Invalid or expired registration"})
    end
  end

  def registration(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "token is required"})
  end

  # Complete registration: verify the token, create the user + session, mint JWTs.
  def register(conn, %{"token" => token} = params) do
    attrs = %{
      first: params["first_name"] || params["first"] || "",
      last: params["last_name"] || params["last"] || "",
      invite_token: params["invite_token"],
      # Cookie-consent choice captured on the register form — persisted on the
      # new account so it carries across the apex → app.* subdomain hop.
      consent: params["consent"]
    }

    with {:ok, identity} <- Therobotplans.Auth.RegistrationToken.verify(token),
         {:ok, created} <- Therobotplans.Auth.SSO.register_user(identity, attrs),
         {:ok, session} <-
           Therobotplans.Users.Sessions.get(created.id, Noizu.Context.system(), []),
         {:ok, access_token, _} <-
           Guardian.encode_and_sign(session, %{}, token_type: "access", ttl: {1, :hour}),
         {:ok, refresh_token, %{"jti" => refresh_jti}} <-
           Guardian.encode_and_sign(session, %{}, token_type: "refresh", ttl: {7, :day}) do
      Therobotplans.Auth.TokenStore.store_refresh_jti(refresh_jti)

      user = resolve_user_from_session(session)
      orgs = Therobotplans.Organizations.list_user_organizations(user.id)

      conn
      |> put_status(:created)
      |> json(%{
        user: serialize_user(user),
        organizations: orgs,
        access_token: access_token,
        refresh_token: refresh_token
      })
    else
      {:error, reason} when reason in [:expired, :invalid] ->
        conn |> put_status(:unauthorized) |> json(%{error: "Invalid or expired registration"})

      {:error, :invite_required} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "A valid invite code is required for this email domain"})

      {:error, :invalid_token} ->
        conn |> put_status(:forbidden) |> json(%{error: "Invalid or expired invite code"})

      {:error, :sso_not_allowed} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "SSO is not available for this email domain"})

      {:error, _} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Registration failed"})
    end
  end

  def register(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "token is required"})
  end

  defp redirect_with_error(conn, error) do
    frontend_url = Application.get_env(:therobotplans, :frontend_url, "http://localhost:3000")
    redirect(conn, external: "#{frontend_url}/auth/sso-callback?error=#{error}")
  end

  defp resolve_user_from_session(%Therobotplans.Users.Sessions.UserSession{} = session) do
    case session.user do
      {:ref, _, id} ->
        {:ok, user} = Therobotplans.Users.get_user(id, Noizu.Context.system())
        user

      %Therobotplans.Users.User{} = user ->
        user
    end
  end

  defp serialize_user(user) do
    # Consent lives on the DB schema row, not the versioned entity — read it back
    # so SSO exchange/register responses carry it (the SPA hydrates from this).
    row = Therobotplans.Repo.get(Therobotplans.Schema.Users.User, user.id)

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
      requires_profile_completion: !Map.get(user, :profile_completed_at),
      consent_preferences: row && row.consent_preferences
    }
  end

  defp maybe_add(list, flag, name) do
    if Application.get_env(:therobotplans, flag), do: [name | list], else: list
  end
end
