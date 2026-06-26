defmodule TherobotsdayjobWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :therobotsdayjob

  socket "/socket", TherobotsdayjobWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :therobotsdayjob
  end

  plug TherobotsdayjobWeb.Plugs.CORS
  plug Plug.RequestId
  plug TherobotsdayjobWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug TherobotsdayjobWeb.Router
end
