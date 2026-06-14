defmodule NoizuSiteWeb.HealthController do
  use NoizuSiteWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
