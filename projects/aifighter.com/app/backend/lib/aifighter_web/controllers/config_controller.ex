defmodule AifighterWeb.ConfigController do
  use AifighterWeb, :controller

  def features(conn, _params) do
    flags = Aifighter.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
