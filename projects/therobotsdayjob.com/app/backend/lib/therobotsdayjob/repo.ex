defmodule Therobotsdayjob.Repo do
  use Ecto.Repo,
    otp_app: :therobotsdayjob,
    adapter: Ecto.Adapters.Postgres
end
