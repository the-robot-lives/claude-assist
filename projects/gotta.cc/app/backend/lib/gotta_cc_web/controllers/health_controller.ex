defmodule GottaCcWeb.HealthController do
  use GottaCcWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
