defmodule IotgoWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :iotgo,
    module: Iotgo.Guardian,
    error_handler: IotgoWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
