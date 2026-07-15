defmodule StyleguideWeb.HealthController do
  use StyleguideWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", viewer: "hologram"})
  end
end
