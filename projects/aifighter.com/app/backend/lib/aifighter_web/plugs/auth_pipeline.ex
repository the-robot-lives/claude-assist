defmodule AifighterWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :aifighter,
    module: Aifighter.Guardian,
    error_handler: AifighterWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
