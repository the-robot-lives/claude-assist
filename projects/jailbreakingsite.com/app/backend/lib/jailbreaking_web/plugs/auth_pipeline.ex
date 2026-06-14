defmodule JailbreakingWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :jailbreaking,
    module: Jailbreaking.Guardian,
    error_handler: JailbreakingWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
