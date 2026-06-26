defmodule ForyouWeb.ConfigController do
  use ForyouWeb, :controller

  def features(conn, _params) do
    flags = Foryou.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
