defmodule Jailbreaking.Repo do
  use Ecto.Repo,
    otp_app: :jailbreaking,
    adapter: Ecto.Adapters.Postgres
end
