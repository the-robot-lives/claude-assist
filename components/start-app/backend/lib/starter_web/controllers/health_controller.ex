defmodule StarterWeb.HealthController do
  use StarterWeb, :controller

  # ⟦𓂓𓏕𓄅𓈩⟧ index :: auto-generated pointer for public function index
  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
