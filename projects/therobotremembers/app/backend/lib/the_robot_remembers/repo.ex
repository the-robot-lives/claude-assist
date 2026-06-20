defmodule TheRobotRemembers.Repo do
  use Ecto.Repo,
    otp_app: :the_robot_remembers,
    adapter: Ecto.Adapters.Postgres
end
