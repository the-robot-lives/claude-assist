defmodule TherobotlivesWeb.HealthController do
  use TherobotlivesWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
