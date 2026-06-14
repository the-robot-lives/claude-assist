defmodule NoizuSiteWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :noizu_site

  socket "/socket", NoizuSiteWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :noizu_site
  end

  plug NoizuSiteWeb.Plugs.CORS
  plug Plug.RequestId
  plug NoizuSiteWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug NoizuSiteWeb.Router
end
