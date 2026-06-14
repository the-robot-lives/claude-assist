defmodule TherobotknowsWeb.ConfigController do
  use TherobotknowsWeb, :controller

  def features(conn, _params) do
    flags = Therobotknows.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
