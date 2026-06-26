defmodule Therobotmakes.Repo do
  use Ecto.Repo,
    otp_app: :therobotmakes,
    adapter: Ecto.Adapters.Postgres
end
