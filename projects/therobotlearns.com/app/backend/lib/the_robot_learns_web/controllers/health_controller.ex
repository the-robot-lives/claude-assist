defmodule TheRobotLearnsWeb.HealthController do
  use TheRobotLearnsWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
