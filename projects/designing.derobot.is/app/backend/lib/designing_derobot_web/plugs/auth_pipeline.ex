defmodule DesigningDerobotWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :designing_derobot,
    module: DesigningDerobot.Guardian,
    error_handler: DesigningDerobotWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
