defmodule ForyouWeb.HealthController do
  use ForyouWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
