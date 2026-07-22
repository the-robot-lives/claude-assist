defmodule HoloGraph.Repo do
  use Ecto.Repo,
    otp_app: :holo_graph,
    adapter: Ecto.Adapters.Postgres
end
