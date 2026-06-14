defmodule GottaCcWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :gotta_cc,
    module: GottaCc.Guardian,
    error_handler: GottaCcWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
