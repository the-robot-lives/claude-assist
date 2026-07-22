defmodule HoloGraphWeb.ConfigController do
  use HoloGraphWeb, :controller

  def features(conn, _params) do
    flags = HoloGraph.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
