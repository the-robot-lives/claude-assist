defmodule DesigningDerobotWeb.HealthControllerTest do
  use DesigningDerobotWeb.ConnCase

  test "GET /health returns ok", %{conn: conn} do
    conn = get(conn, "/health")
    assert json_response(conn, 200)["status"] == "ok"
  end
end
