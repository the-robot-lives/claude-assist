defmodule TheRobotRemembersWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :the_robot_remembers,
    module: TheRobotRemembers.Guardian,
    error_handler: TheRobotRemembersWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
