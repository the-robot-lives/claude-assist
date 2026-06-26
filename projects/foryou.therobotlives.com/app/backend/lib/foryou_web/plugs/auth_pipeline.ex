defmodule ForyouWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :foryou,
    module: Foryou.Guardian,
    error_handler: ForyouWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
