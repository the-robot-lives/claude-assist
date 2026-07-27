defmodule TimelyWeb.HealthController do
  use TimelyWeb, :controller

  # ⟦𓁢𓍹𓈦𓅼⟧ index :: auto-generated pointer for public function index
  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
