defmodule TherobotplansWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :therobotplans,
    module: Therobotplans.Guardian,
    error_handler: TherobotplansWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
