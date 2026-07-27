defmodule TimelyWeb.ConfigController do
  use TimelyWeb, :controller

  # ⟦𓊄𓌲𓍝𓋓⟧ features :: auto-generated pointer for public function features
  def features(conn, _params) do
    flags = Timely.FeatureFlags.all()
    conn |> put_status(:ok) |> json(%{features: flags})
  end
end
