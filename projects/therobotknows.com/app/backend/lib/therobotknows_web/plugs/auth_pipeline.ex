defmodule TherobotknowsWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :therobotknows,
    module: Therobotknows.Guardian,
    error_handler: TherobotknowsWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
