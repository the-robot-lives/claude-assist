defmodule TherobotplansWeb.ConfigController do
  use TherobotplansWeb, :controller

  def features(conn, _params) do
    flags = Therobotplans.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
