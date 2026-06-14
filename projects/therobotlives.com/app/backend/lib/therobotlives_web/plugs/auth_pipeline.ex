defmodule TherobotlivesWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :therobotlives,
    module: Therobotlives.Guardian,
    error_handler: TherobotlivesWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
