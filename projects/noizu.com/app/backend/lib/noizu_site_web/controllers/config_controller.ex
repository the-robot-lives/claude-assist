defmodule NoizuSiteWeb.ConfigController do
  use NoizuSiteWeb, :controller

  def features(conn, _params) do
    flags = NoizuSite.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
