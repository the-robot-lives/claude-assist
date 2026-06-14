defmodule NoizuSiteWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :noizu_site,
    module: NoizuSite.Guardian,
    error_handler: NoizuSiteWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
