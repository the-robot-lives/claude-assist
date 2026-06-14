defmodule AifighterWeb.HealthController do
  use AifighterWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
