defmodule TheRobotLearnsWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :the_robot_learns,
    module: TheRobotLearns.Guardian,
    error_handler: TheRobotLearnsWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
