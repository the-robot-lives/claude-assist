defmodule DesigningDerobotWeb.ConfigController do
  use DesigningDerobotWeb, :controller

  def features(conn, _params) do
    flags = DesigningDerobot.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
