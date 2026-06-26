defmodule TherobotmakesWeb.ConfigController do
  use TherobotmakesWeb, :controller

  def features(conn, _params) do
    flags = Therobotmakes.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
