defmodule StyleguideWeb.Hologram.Layouts.MainLayout do
  @moduledoc "Root layout: theme CSS, fonts, site nav, Hologram runtime."
  use Hologram.Component

  alias Hologram.UI.Link
  alias Styleguide.Auth
  alias Styleguide.Catalog
  alias StyleguideWeb.Hologram.Pages.AppDashboardPage
  alias StyleguideWeb.Hologram.Pages.LandingPage
  alias StyleguideWeb.Hologram.Pages.LoginPage
  alias StyleguideWeb.Hologram.Pages.StyleGuidePage
  alias StyleguideWeb.Hologram.Pages.TailwindPlusPage

  prop :page_title, :string, default: "Style Guide"

  def init(_props, component, server) do
    theme_slug = Hologram.Server.get_cookie(server, "sg-theme", "style-guide")
    theme = Catalog.get_theme(theme_slug)
    color_mode = Hologram.Server.get_cookie(server, "color-mode", "system")
    user = Auth.current_user(server)

    component =
      put_state(component,
        theme_slug: theme.slug,
        theme_css: theme.css,
        themes: Catalog.themes(),
        color_mode: color_mode,
        brand: Catalog.brand(),
        user: user,
        user_email: user && user.email
      )

    {component, server}
  end

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html lang="en" data-design-theme={@theme_slug} class={html_class(@color_mode)}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@page_title}</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link rel="stylesheet" href={@brand.font_url} />
        <link rel="stylesheet" href={@theme_css} />
        <link rel="stylesheet" href="/css/viewer.css" />
        <Hologram.UI.Runtime />
      </head>
      <body>
        <a class="skip-link" href="#main">Skip to content</a>
        <header class="sg-viewer-bar">
          <div class="sg-viewer-bar__left">
            <Link to={LandingPage} class="sg-viewer-bar__brand">{@brand.logo_text}</Link>
            <nav class="sg-site-nav" aria-label="Primary">
              <Link to={LandingPage} class="sg-site-nav__link">Home</Link>
              {%if @user_email}
                <Link to={AppDashboardPage} class="sg-site-nav__link">Dashboard</Link>
              {/if}
              <Link to={StyleGuidePage} class="sg-site-nav__link">Style guide</Link>
              <Link to={TailwindPlusPage} class="sg-site-nav__link">Tailwind Plus</Link>
              {%if @user_email}
                <Link to={AppDashboardPage} class="sg-site-nav__link">{@user_email}</Link>
                <a href="/auth/logout" class="sg-site-nav__link">Sign out</a>
              {%else}
                <Link to={LoginPage} class="sg-site-nav__link">Log in</Link>
              {/if}
            </nav>
          </div>
          <div class="sg-viewer-bar__controls">
            <label for="theme-select" style="font-size: var(--font-size-xs); opacity: 0.7">Theme</label>
            <select id="theme-select" $change={action: :set_theme, target: "layout"}>
              {%for t <- @themes}
                <option value={t.slug} selected={t.slug == @theme_slug}>{t.name}</option>
              {/for}
            </select>
            <button type="button" class="btn btn-outline btn-sm" $click={action: :toggle_dark, target: "layout"}>
              {%if @color_mode == "dark"}Light{%else}Dark{/if}
            </button>
          </div>
        </header>
        <main id="main">
          <slot />
        </main>
      </body>
    </html>
    """
  end

  def html_class("dark"), do: "dark"
  def html_class(_), do: ""

  def action(:set_theme, params, component) do
    slug = params.event.value
    theme = Catalog.get_theme(slug)

    component
    |> put_state(theme_slug: theme.slug, theme_css: theme.css)
    |> put_command(:persist_theme, slug: theme.slug)
  end

  def action(:toggle_dark, _params, component) do
    next = if component.state.color_mode == "dark", do: "light", else: "dark"

    component
    |> put_state(:color_mode, next)
    |> put_command(:persist_color_mode, mode: next)
  end

  def command(:persist_theme, params, server) do
    Hologram.Server.put_cookie(server, "sg-theme", params.slug,
      http_only: false,
      max_age: 60 * 60 * 24 * 365,
      secure: false
    )
  end

  def command(:persist_color_mode, params, server) do
    Hologram.Server.put_cookie(server, "color-mode", params.mode,
      http_only: false,
      max_age: 60 * 60 * 24 * 365,
      secure: false
    )
  end
end
