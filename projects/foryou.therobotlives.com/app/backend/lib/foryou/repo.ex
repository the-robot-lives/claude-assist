defmodule Foryou.Repo do
  use Ecto.Repo,
    otp_app: :foryou,
    adapter: Ecto.Adapters.Postgres
end
