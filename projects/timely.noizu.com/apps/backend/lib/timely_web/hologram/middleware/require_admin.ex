defmodule TimelyWeb.Hologram.Middleware.RequireAdmin do
  @moduledoc "Require authenticated platform admin; otherwise redirect to `/app`."
  use Hologram.Middleware

  alias Timely.Hologram.Auth
  alias TimelyWeb.Hologram.Pages.AppHomePage
  alias TimelyWeb.Hologram.Pages.LoginPage

  # ⟦𓇪𓇧𓂻𓇿⟧ call :: auto-generated pointer for public function call
  def call(server, _opts) do
    case Auth.current_user(server) do
      nil ->
        Hologram.Server.put_redirect(server, LoginPage)

      user ->
        if admin?(user) do
          Hologram.Server.put_stash(server, :current_user, user)
        else
          Hologram.Server.put_redirect(server, AppHomePage)
        end
    end
  end

  defp admin?(user) do
    is_map(user) and
      (user[:is_admin] == true or user["is_admin"] == true or
         user[:admin] == true or user["admin"] == true)
  end
end
