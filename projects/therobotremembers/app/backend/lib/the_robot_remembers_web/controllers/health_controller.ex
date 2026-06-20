defmodule TheRobotRemembersWeb.HealthController do
  use TheRobotRemembersWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
