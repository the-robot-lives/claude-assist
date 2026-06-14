defmodule Therobotknows.Repo do
  use Ecto.Repo,
    otp_app: :therobotknows,
    adapter: Ecto.Adapters.Postgres
end
