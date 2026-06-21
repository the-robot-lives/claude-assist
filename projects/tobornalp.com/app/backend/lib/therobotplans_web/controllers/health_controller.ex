defmodule TherobotplansWeb.HealthController do
  use TherobotplansWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
