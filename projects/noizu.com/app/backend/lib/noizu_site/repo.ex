defmodule NoizuSite.Repo do
  use Ecto.Repo,
    otp_app: :noizu_site,
    adapter: Ecto.Adapters.Postgres
end
