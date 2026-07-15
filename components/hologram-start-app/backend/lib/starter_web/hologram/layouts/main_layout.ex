defmodule StarterWeb.Hologram.Layouts.MainLayout do
  @moduledoc """
  Root Hologram layout: style-guide CSS, runtime, navbar, cookie consent.

  Loads the YAML-generated design system from `/themes/design-system.generated.css`
  (produced by `@noizu/styleguide` from `assets/theme-style-guide/`).
  """
  use Hologram.Component

  alias Starter.Hologram.Auth
  alias StarterWeb.Hologram.Components.CookieConsent
  alias StarterWeb.Hologram.Components.Navbar

  prop :page_title, :string, default: "Start-App: Tagline"
  prop :brand, :string, default: "Start-App: Tagline"

  def init(_props, component, server) do
    {user, organizations} = Auth.current_user_and_orgs(server)
    consent = Hologram.Server.get_session(server, :cookie_consent)
    color_mode = Hologram.Server.get_cookie(server, "color-mode", "system")

    component =
      put_state(component,
        user: user,
        organizations: organizations || [],
        show_cookie_banner: is_nil(consent),
        color_mode: color_mode
      )

    {component, server}
  end

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en" data-design-theme="style-guide" class={html_class(@color_mode)}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@page_title}</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=IBM+Plex+Mono:ital,wght@0,300;0,400;0,500;0,600;1,400&display=swap"
        />
        <link rel="stylesheet" href="/themes/design-system.generated.css" />
        <link rel="stylesheet" href="/css/app.css" />
        <Hologram.UI.Runtime />
      </head>
      <body>
        <a class="skip-link" href="#main">Skip to content</a>
        <Navbar user={@user} brand={@brand} />
        <main id="main">
          <slot />
        </main>
        <CookieConsent cid="cookie_consent" visible={@show_cookie_banner} />
      </body>
    </html>
    """
  end

  def html_class("dark"), do: "dark"
  def html_class(_), do: ""

  # ── actions (layout-owned: cookies + logout) ─────────────────

  def action(:accept_all_cookies, _params, component) do
    component
    |> put_state(:show_cookie_banner, false)
    |> put_command(:save_cookie_consent, analytics: true, marketing: true, preferences: true)
  end

  def action(:reject_optional_cookies, _params, component) do
    component
    |> put_state(:show_cookie_banner, false)
    |> put_command(:save_cookie_consent, analytics: false, marketing: false, preferences: false)
  end

  def action(:logout, _params, component) do
    component
    |> put_state(user: nil, organizations: [])
    |> put_command(:logout)
  end

  # ── commands ─────────────────────────────────────────────────

  def command(:save_cookie_consent, params, server) do
    consent = %{
      version: 1,
      necessary: true,
      analytics: Map.get(params, :analytics, false),
      marketing: Map.get(params, :marketing, false),
      preferences: Map.get(params, :preferences, false),
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Hologram.Server.put_session(server, :cookie_consent, consent)
  end

  def command(:logout, _params, server) do
    server
    |> Auth.logout()
    |> Hologram.Server.put_redirect(StarterWeb.Hologram.Pages.HomePage)
  end
end

