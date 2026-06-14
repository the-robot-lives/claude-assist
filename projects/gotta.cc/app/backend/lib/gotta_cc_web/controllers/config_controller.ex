defmodule GottaCcWeb.ConfigController do
  use GottaCcWeb, :controller

  def features(conn, _params) do
    flags = GottaCc.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
