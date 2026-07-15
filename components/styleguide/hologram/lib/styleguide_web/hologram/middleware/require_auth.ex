defmodule StyleguideWeb.Hologram.Middleware.RequireAuth do
  @moduledoc "Redirect unauthenticated users to LoginPage."
  use Hologram.Middleware

  alias Styleguide.Auth
  alias StyleguideWeb.Hologram.Pages.LoginPage

  def call(server, _opts) do
    if Auth.current_user(server) do
      server
    else
      Hologram.Server.put_redirect(server, LoginPage)
    end
  end
end
