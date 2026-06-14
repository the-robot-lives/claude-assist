defmodule Iotgo.Repo do
  use Ecto.Repo,
    otp_app: :iotgo,
    adapter: Ecto.Adapters.Postgres
end
