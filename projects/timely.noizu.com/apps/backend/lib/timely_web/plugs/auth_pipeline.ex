defmodule TimelyWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :timely,
    module: Timely.Guardian,
    error_handler: TimelyWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
