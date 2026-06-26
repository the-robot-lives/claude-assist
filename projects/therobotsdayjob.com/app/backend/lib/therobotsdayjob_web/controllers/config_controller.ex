defmodule TherobotsdayjobWeb.ConfigController do
  use TherobotsdayjobWeb, :controller

  def features(conn, _params) do
    flags = Therobotsdayjob.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
