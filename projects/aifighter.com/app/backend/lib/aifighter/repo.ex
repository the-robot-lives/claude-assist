defmodule Aifighter.Repo do
  use Ecto.Repo,
    otp_app: :aifighter,
    adapter: Ecto.Adapters.Postgres
end
