defmodule TherobotknowsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :therobotknows

  socket "/socket", TherobotknowsWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :therobotknows
  end

  plug TherobotknowsWeb.Plugs.CORS
  plug Plug.RequestId
  plug TherobotknowsWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug TherobotknowsWeb.Router
end
