defmodule TherobotsdayjobWeb.HealthController do
  use TherobotsdayjobWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
