defmodule TherobotmakesWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :therobotmakes

  socket "/socket", TherobotmakesWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :therobotmakes
  end

  plug TherobotmakesWeb.Plugs.CORS
  plug Plug.RequestId
  plug TherobotmakesWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug TherobotmakesWeb.Router
end
