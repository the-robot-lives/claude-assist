defmodule TherobotknowsWeb.HealthController do
  use TherobotknowsWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
