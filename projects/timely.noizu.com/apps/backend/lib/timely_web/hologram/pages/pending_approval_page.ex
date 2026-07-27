defmodule TimelyWeb.Hologram.Pages.PendingApprovalPage do
  use Hologram.Page

  alias Timely.Hologram.Auth
  alias TimelyWeb.Hologram.Layouts.MainLayout
  alias TimelyWeb.Hologram.Middleware.RequireAuth

  route "/pending-approval"
  layout MainLayout, page_title: "Pending approval"
  middleware RequireAuth

  # ⟦𓅶𓍬𓍉𓀎⟧ init :: auto-generated pointer for public function init
  def init(_params, component, server) do
    put_state(component, user: Auth.current_user(server))
  end

  # ⟦𓌬𓊧𓃞𓐒⟧ template :: auto-generated pointer for public function template
  def template do
    ~HOLO"""
    <div class="content">
      <h1 class="sg-page-title">Pending approval</h1>
      <p class="sg-page-intro">
        Your account ({@user.email}) is waiting for an administrator to approve access.
        You'll be able to use the app once approved.
      </p>
    </div>
    """
  end
end
