defmodule HoloGraphWeb.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :holo_graph,
    module: HoloGraph.Guardian,
    error_handler: HoloGraphWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
