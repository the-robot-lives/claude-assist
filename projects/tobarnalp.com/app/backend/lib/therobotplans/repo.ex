defmodule Therobotplans.Repo do
  use Ecto.Repo,
    otp_app: :therobotplans,
    adapter: Ecto.Adapters.Postgres
end
