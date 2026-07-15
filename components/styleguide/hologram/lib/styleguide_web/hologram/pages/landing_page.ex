defmodule StyleguideWeb.Hologram.Pages.LandingPage do
  @moduledoc """
  Site landing at `/` — marketing hero only.

  Entry points: Log in · View style guide (and Tailwind Plus catalog).
  """
  use Hologram.Page

  alias Hologram.UI.Link
  alias Styleguide.Catalog
  alias StyleguideWeb.Hologram.Components.ButtonRow
  alias StyleguideWeb.Hologram.Components.Card
  alias StyleguideWeb.Hologram.Components.CardGrid
  alias StyleguideWeb.Hologram.Layouts.MainLayout
  alias StyleguideWeb.Hologram.Pages.LoginPage
  alias StyleguideWeb.Hologram.Pages.StyleGuidePage
  alias StyleguideWeb.Hologram.Pages.TailwindPlusPage

  route "/"
  layout MainLayout, page_title: "NOIZU.INK"

  def init(_params, component, _server) do
    put_state(component,
      brand: Catalog.brand(),
      themes: Catalog.themes()
    )
  end

  def template do
    ~HOLO"""
    <div class="content landing">
      <section class="landing-hero">
        <p class="landing-kicker">{@brand.logo_text}</p>
        <h1 class="landing-title">Design systems that ship.</h1>
        <p class="landing-lead">
          YAML seeds expand into tokens, themes, and interactive previews.
          Browse the style guide, sign in with Authentik, or open the
          Tailwind Plus catalog — all on Hologram, no TypeScript runtime.
        </p>
        <ButtonRow class="landing-cta">
          <Link to={LoginPage} class="btn btn-outline">Log in</Link>
          <Link to={StyleGuidePage} class="btn btn-black">View style guide</Link>
        </ButtonRow>
      </section>

      <CardGrid>
        <Card
          title="Style guide"
          body="Visual foundation, shells, HUI controls, component browser, YAML config, and full color palettes."
        >
          <p><Link to={StyleGuidePage} class="btn btn-outline btn-sm">Open viewer</Link></p>
        </Card>
        <Card
          title="Tailwind Plus"
          body="686 static HTML widget demos themed by the design system — forms, marketing, ecommerce, and more."
        >
          <p><Link to={TailwindPlusPage} class="btn btn-outline btn-sm">Open catalog</Link></p>
        </Card>
        <Card
          title="Log in"
          body="Authentik SSO (OpenID Connect) — same OIDC flow as hologram-start-app."
        >
          <p><Link to={LoginPage} class="btn btn-outline btn-sm">Go to login</Link></p>
        </Card>
      </CardGrid>

      <section class="landing-themes">
        <h2 class="landing-section-title">Themes</h2>
        <p class="app-muted" style="margin-bottom: var(--space-2)">
          Switch theme anytime from the top bar — CSS is prebuilt per theme.
        </p>
        <ul class="landing-theme-list">
          {%for t <- @themes}
            <li><code>{t.slug}</code> — {t.name}</li>
          {/for}
        </ul>
      </section>
    </div>
    """
  end
end
