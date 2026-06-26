defmodule TherobotsdayjobWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :therobotsdayjob,
    module: Therobotsdayjob.Guardian,
    error_handler: TherobotsdayjobWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
