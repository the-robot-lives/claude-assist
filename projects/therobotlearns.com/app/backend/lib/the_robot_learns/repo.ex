defmodule TheRobotLearns.Repo do
  use Ecto.Repo,
    otp_app: :the_robot_learns,
    adapter: Ecto.Adapters.Postgres
end
