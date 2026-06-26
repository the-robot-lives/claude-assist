defmodule TherobotmakesWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :therobotmakes,
    module: Therobotmakes.Guardian,
    error_handler: TherobotmakesWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
