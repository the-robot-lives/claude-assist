defmodule StarterWeb.Hologram.Pages.HomePage do
  @moduledoc "Landing page — style-guide cards + CTAs (start-app home)."
  use Hologram.Page

  alias Hologram.UI.Link
  alias StarterWeb.Hologram.Components.ButtonRow
  alias StarterWeb.Hologram.Components.Card
  alias StarterWeb.Hologram.Components.CardGrid
  alias StarterWeb.Hologram.Layouts.MainLayout
  alias StarterWeb.Hologram.Pages.LoginPage
  alias StarterWeb.Hologram.Pages.SignupPage
  alias StarterWeb.Hologram.Pages.SitemapPage

  route "/"
  layout MainLayout, page_title: "Start-App: Tagline"

  def init(_params, component, _server) do
    put_state(component, :ready, true)
  end

  def template do
    ~HOLO"""
    <div class="content">
      <h1 class="sg-page-title">Start-App: Tagline</h1>
      <p class="sg-page-intro">
        Edit this page to build your project. Auth, registration, consent, and the
        <strong>login → app home → org dashboard</strong> flow are ready — Hologram UI
        on the style-guide design system.
      </p>
      <ButtonRow class="sg-page-cta">
        <Link to={LoginPage} class="btn btn-outline">Log In</Link>
        <Link to={SignupPage} class="btn btn-black">Get Started</Link>
        <Link to={SitemapPage} class="btn btn-outline">Site Map</Link>
      </ButtonRow>
      <CardGrid>
        <Card
          title="Accounts"
          body="Email/password, SSO, invites, magic links, and approval states."
        />
        <Card
          title="App shell"
          body="After login: /app home, profile, and /app/:org_id dashboard with sidebar chrome."
        />
        <Card
          title="Isomorphic Elixir"
          body="Hologram keeps state in the browser — actions are instant, commands hit the server."
        />
      </CardGrid>
    </div>
    """
  end
end
