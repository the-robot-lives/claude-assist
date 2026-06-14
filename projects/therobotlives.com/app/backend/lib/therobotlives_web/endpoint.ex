defmodule TherobotlivesWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :therobotlives

  socket "/socket", TherobotlivesWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :therobotlives
  end

  plug TherobotlivesWeb.Plugs.CORS
  plug Plug.RequestId
  plug TherobotlivesWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug TherobotlivesWeb.Router
end
