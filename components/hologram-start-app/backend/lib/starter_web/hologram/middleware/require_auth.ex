defmodule StarterWeb.Hologram.Middleware.RequireAuth do
  @moduledoc "Redirect unauthenticated visitors to the login page."
  use Hologram.Middleware

  alias Starter.Hologram.Auth
  alias StarterWeb.Hologram.Pages.LoginPage

  # ⟦𓋔𓇖𓌣𓊒⟧ call :: auto-generated pointer for public function call
  def call(server, _opts) do
    case Auth.current_user(server) do
      nil ->
        Hologram.Server.put_redirect(server, LoginPage)

      user ->
        Hologram.Server.put_stash(server, :current_user, user)
    end
  end
end

