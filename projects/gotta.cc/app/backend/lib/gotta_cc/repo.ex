defmodule GottaCc.Repo do
  use Ecto.Repo,
    otp_app: :gotta_cc,
    adapter: Ecto.Adapters.Postgres
end
