defmodule StyleguideWeb.Hologram.Pages.LoginPage do
  @moduledoc """
  Login at `/login` — Authentik (OIDC) SSO.

  Flow: SSO → `/auth/oidc` → Authentik → `/auth/oidc/callback` →
  `/auth/sso-callback` → **`/app`** (dashboard).
  """
  use Hologram.Page

  alias Hologram.UI.Link
  alias Styleguide.Auth
  alias StyleguideWeb.Hologram.Layouts.MainLayout
  alias StyleguideWeb.Hologram.Pages.AppDashboardPage
  alias StyleguideWeb.Hologram.Pages.LandingPage
  alias StyleguideWeb.Hologram.Pages.StyleGuidePage

  route "/login"
  layout MainLayout, page_title: "Log In"

  def init(_params, component, server) do
    catalog = Auth.sso_catalog()
    status = Auth.config_status()
    user = Auth.current_user(server)
    query = server.query || %{}
    error = Map.get(query, "error")

    # Already signed in → go to dashboard
    if user do
      component =
        put_state(component,
          step: "signed_in",
          email: user.email,
          user_name: user.name || "",
          error: nil,
          sso_enabled: catalog.enabled,
          sso_path: catalog.path,
          sso_label: catalog.label,
          issuer: status[:issuer] || "",
          redirect_uri: status[:redirect_uri] || "http://localhost:4500/auth/oidc/callback",
          missing_text: "",
          has_missing: false,
          dotenv_loaded: true,
          client_id_ok: true,
          client_secret_ok: true,
          issuer_ok: true,
          env_snippet: "",
          auto_go_app: true
        )

      {component, server}
    else
      put_state(component,
        step: "ready",
        email: "",
        user_name: "",
        error: error_message(error),
        sso_enabled: catalog.enabled,
        sso_path: catalog.path,
        sso_label: catalog.label,
        issuer: status[:issuer] || "",
        redirect_uri: status[:redirect_uri] || "http://localhost:4500/auth/oidc/callback",
        missing_text: status[:missing_text] || "",
        has_missing: status[:has_missing] == true,
        dotenv_loaded: status[:dotenv_loaded] == true,
        client_id_ok: status[:client_id_set] == true,
        client_secret_ok: status[:client_secret_set] == true,
        issuer_ok: status[:issuer_set] == true,
        env_snippet: env_snippet(),
        auto_go_app: false
      )
    end
  end

  def template do
    ~HOLO"""
    <div class="content login-page">
      <p class="twp-back">
        <Link to={LandingPage} class="btn btn-outline btn-sm">← Home</Link>
      </p>

      <div class="login-panel">
        <p class="login-brand">NOIZU.INK</p>
        <h1 class="login-title">Log in</h1>
        <p class="login-sub">Sign in with Authentik (SSO) to continue</p>

        {%if @error}
          <p class="sg-error" role="alert">{@error}</p>
        {/if}

        {%if @step == "signed_in"}
          <div class="login-form" style="text-align: center">
            <p class="login-success">Signed in as <strong>{@email}</strong></p>
            {%if @user_name != "" and @user_name != @email}
              <p class="app-muted">{@user_name}</p>
            {/if}
            <a href="/app" class="btn btn-black login-full-btn">Go to dashboard</a>
            <Link to={StyleGuidePage} class="btn btn-outline" style="width: 100%; margin-top: var(--space-1)">
              View style guide
            </Link>
            <a href="/auth/logout" class="btn btn-outline login-full-btn">Sign out</a>
            {%if @auto_go_app}
              <script>window.location.replace("/app");</script>
            {/if}
          </div>
        {/if}

        {%if @step == "ready"}
          {%if @sso_enabled}
            <div class="login-sso-primary">
              <a href={@sso_path} class="btn btn-black login-full-btn">{@sso_label}</a>
              <p class="app-muted" style="text-align: center; margin: var(--space-2) 0 0; font-size: var(--font-size-xs)">
                Authentik · OpenID Connect
                {%if @issuer != ""}
                  · <code style="font-size: 10px">{@issuer}</code>
                {/if}
              </p>
            </div>
          {%else}
            <div class="login-setup">
              <p class="sg-error" role="status">SSO is not configured yet.</p>
              <p class="app-muted" style="font-size: var(--font-size-sm); margin-bottom: var(--space-2)">
                Create an OAuth2/OIDC application in Authentik, then put credentials in
                <code>components/styleguide/hologram/.env</code> and restart <code>mix holo</code>.
              </p>

              <div class="login-checklist">
                <div class={if @issuer_ok do "login-check login-check--ok" else "login-check" end}>
                  <span>{if @issuer_ok do "✓" else "○" end}</span>
                  <code>OIDC_ISSUER</code>
                </div>
                <div class={if @client_id_ok do "login-check login-check--ok" else "login-check" end}>
                  <span>{if @client_id_ok do "✓" else "○" end}</span>
                  <code>OIDC_CLIENT_ID</code>
                </div>
                <div class={if @client_secret_ok do "login-check login-check--ok" else "login-check" end}>
                  <span>{if @client_secret_ok do "✓" else "○" end}</span>
                  <code>OIDC_CLIENT_SECRET</code>
                </div>
                <div class={if @dotenv_loaded do "login-check login-check--ok" else "login-check" end}>
                  <span>{if @dotenv_loaded do "✓" else "○" end}</span>
                  <code>.env</code> file present
                </div>
              </div>

              {%if @has_missing}
                <p class="app-muted" style="font-size: var(--font-size-xs); margin-top: var(--space-2)">
                  Missing: <strong>{@missing_text}</strong>
                </p>
              {/if}

              <pre class="login-env-snippet">{@env_snippet}</pre>

              <p class="app-muted" style="font-size: var(--font-size-xs); margin-top: var(--space-2)">
                Authentik redirect URI must be exactly:
                <code>{@redirect_uri}</code>
              </p>
              <p class="app-muted" style="font-size: var(--font-size-xs)">
                Aliases also work: <code>STYLEGUIDE_OIDC_*</code> or <code>START_APP_OIDC_*</code>.
              </p>
            </div>
          {/if}
        {/if}

        <p class="login-footer">
          <Link to={LandingPage}>Back to home</Link>
          ·
          <Link to={StyleGuidePage}>Style guide</Link>
        </p>
      </div>
    </div>
    """
  end

  defp env_snippet do
    """
    # components/styleguide/hologram/.env
    # Same Authentik app as hologram-start-app (startapp):
    OIDC_ISSUER=https://auth.derobot.is/application/o/startapp
    OIDC_CLIENT_ID=<START_APP_OIDC_CLIENT_ID>
    OIDC_CLIENT_SECRET=<START_APP_OIDC_CLIENT_SECRET>
    OIDC_REDIRECT_URI=http://localhost:4500/auth/oidc/callback
    """
  end

  defp error_message(nil), do: nil
  defp error_message(""), do: nil
  defp error_message("sso_disabled"), do: "SSO is not enabled. Add OIDC_* to .env and restart."
  defp error_message("sso_misconfigured"), do: "SSO is misconfigured (missing OpenID provider config)."
  defp error_message("oidc_failed"), do: "Authentik sign-in failed. Try again or contact an admin."
  defp error_message("oidc_state"), do: "SSO session expired or invalid. Start sign-in again."
  defp error_message("oidc_no_email"), do: "Authentik did not return an email claim."
  defp error_message("oidc_init"), do: "Could not start Authentik login. Check OIDC_ISSUER and network."
  defp error_message(other), do: "Sign-in error: #{other}"
end
