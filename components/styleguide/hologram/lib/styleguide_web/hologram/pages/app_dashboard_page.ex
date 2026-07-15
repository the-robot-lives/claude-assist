defmodule StyleguideWeb.Hologram.Pages.AppDashboardPage do
  @moduledoc """
  Post-login app home at `/app`.

  Authentik SSO lands here. Offers the style-guide viewer, Tailwind Plus catalog,
  and account summary — same role as hologram-start-app `/app`.
  """
  use Hologram.Page

  alias Hologram.UI.Link
  alias Styleguide.Auth
  alias Styleguide.Catalog
  alias StyleguideWeb.Hologram.Layouts.MainLayout
  alias StyleguideWeb.Hologram.Middleware.RequireAuth
  alias StyleguideWeb.Hologram.Pages.LandingPage
  alias StyleguideWeb.Hologram.Pages.StyleGuidePage
  alias StyleguideWeb.Hologram.Pages.TailwindPlusPage

  route "/app"
  layout MainLayout, page_title: "Dashboard"
  middleware RequireAuth

  def init(_params, component, server) do
    user = Auth.current_user(server)

    put_state(component,
      user: user,
      display_name: display_name(user),
      user_email: user && user.email,
      user_name: user && user.name,
      user_sub: (user && user.sub) || "—",
      themes: Catalog.themes(),
      theme_count: length(Catalog.themes()),
      greeting: greeting_for()
    )
  end

  def template do
    ~HOLO"""
    <div class="content app-dash">
      <div class="app-dash-welcome">
        <div>
          <p class="app-dash-welcome__kicker">{@greeting}</p>
          <h1 class="app-dash-welcome__name">{@display_name}</h1>
          <p class="app-muted">{@user_email}</p>
        </div>
        <div class="app-dash-welcome__actions">
          <a href="/auth/logout" class="btn btn-outline btn-sm">Sign out</a>
        </div>
      </div>

      <div class="app-kpi-row">
        <div class="app-kpi">
          <div class="app-kpi__value">SSO</div>
          <div class="app-kpi__label">Auth</div>
        </div>
        <div class="app-kpi">
          <div class="app-kpi__value">{@theme_count}</div>
          <div class="app-kpi__label">Themes</div>
        </div>
        <div class="app-kpi">
          <div class="app-kpi__value">Live</div>
          <div class="app-kpi__label">Session</div>
        </div>
      </div>

      <div class="app-dash-grid">
        <section class="app-dash-panel">
          <h2 class="app-dash-panel__title">Style system</h2>
          <div class="app-dash-panel__body app-stack-gap">
            <p class="app-muted">
              Browse tokens, color palettes, shells, HUI controls, and YAML config
              for the active theme.
            </p>
            <Link to={StyleGuidePage} class="btn btn-black">Open style guide</Link>
          </div>
        </section>

        <section class="app-dash-panel">
          <h2 class="app-dash-panel__title">Tailwind Plus</h2>
          <div class="app-dash-panel__body app-stack-gap">
            <p class="app-muted">
              686 static HTML demos themed with design-system tokens.
            </p>
            <Link to={TailwindPlusPage} class="btn btn-outline">Open catalog</Link>
          </div>
        </section>

        <section class="app-dash-panel">
          <h2 class="app-dash-panel__title">Account</h2>
          <div class="app-dash-panel__body">
            <dl class="app-dl">
              <div class="app-dl__row">
                <dt>Email</dt>
                <dd>{@user_email}</dd>
              </div>
              <div class="app-dl__row">
                <dt>Name</dt>
                <dd>{@user_name}</dd>
              </div>
              <div class="app-dl__row">
                <dt>Subject</dt>
                <dd><code class="app-code">{@user_sub}</code></dd>
              </div>
            </dl>
          </div>
        </section>
      </div>

      <p class="app-muted" style="margin-top: var(--space-4)">
        <Link to={LandingPage}>← Home</Link>
      </p>
    </div>
    """
  end

  defp display_name(nil), do: "there"
  defp display_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp display_name(%{email: email}) when is_binary(email), do: email |> String.split("@") |> hd()
  defp display_name(_), do: "there"

  defp greeting_for do
    hour = DateTime.utc_now().hour

    cond do
      hour < 12 -> "Good morning"
      hour < 18 -> "Good afternoon"
      true -> "Good evening"
    end
  end
end
