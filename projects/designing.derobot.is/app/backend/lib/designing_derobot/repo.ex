defmodule DesigningDerobot.Repo do
  use Ecto.Repo,
    otp_app: :designing_derobot,
    adapter: Ecto.Adapters.Postgres
end
