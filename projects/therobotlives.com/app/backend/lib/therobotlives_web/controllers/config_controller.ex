defmodule TherobotlivesWeb.ConfigController do
  use TherobotlivesWeb, :controller

  def features(conn, _params) do
    flags = Therobotlives.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
