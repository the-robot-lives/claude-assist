defmodule CodefreshWeb.ConfigController do
  use CodefreshWeb, :controller

  def features(conn, _params) do
    flags = Codefresh.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
