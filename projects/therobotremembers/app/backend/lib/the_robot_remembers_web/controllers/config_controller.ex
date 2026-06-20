defmodule TheRobotRemembersWeb.ConfigController do
  use TheRobotRemembersWeb, :controller

  def features(conn, _params) do
    flags = TheRobotRemembers.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
