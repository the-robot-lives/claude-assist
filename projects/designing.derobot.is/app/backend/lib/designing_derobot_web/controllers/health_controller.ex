defmodule DesigningDerobotWeb.HealthController do
  use DesigningDerobotWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
