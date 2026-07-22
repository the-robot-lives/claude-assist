defmodule TheRobotLearnsWeb.ConfigController do
  use TheRobotLearnsWeb, :controller

  def features(conn, _params) do
    flags = TheRobotLearns.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
