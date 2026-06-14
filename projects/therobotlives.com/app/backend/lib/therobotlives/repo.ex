defmodule Therobotlives.Repo do
  use Ecto.Repo,
    otp_app: :therobotlives,
    adapter: Ecto.Adapters.Postgres
end
