defmodule IotgoWeb.ConfigController do
  use IotgoWeb, :controller

  def features(conn, _params) do
    flags = Iotgo.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
