defmodule AifighterWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :aifighter

  socket "/socket", AifighterWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :aifighter
  end

  plug AifighterWeb.Plugs.CORS
  plug Plug.RequestId
  plug AifighterWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug AifighterWeb.Router
end
