defmodule StarterWeb.Hologram.Pages.PendingApprovalPage do
  use Hologram.Page

  alias Starter.Hologram.Auth
  alias StarterWeb.Hologram.Layouts.MainLayout
  alias StarterWeb.Hologram.Middleware.RequireAuth

  route "/pending-approval"
  layout MainLayout, page_title: "Pending approval"
  middleware RequireAuth

  def init(_params, component, server) do
    put_state(component, user: Auth.current_user(server))
  end

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
