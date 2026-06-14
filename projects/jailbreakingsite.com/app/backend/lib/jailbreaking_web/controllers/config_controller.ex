defmodule JailbreakingWeb.ConfigController do
  use JailbreakingWeb, :controller

  def features(conn, _params) do
    flags = Jailbreaking.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
