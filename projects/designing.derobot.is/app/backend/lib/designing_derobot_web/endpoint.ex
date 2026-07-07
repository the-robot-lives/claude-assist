defmodule DesigningDerobotWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :designing_derobot

  socket "/socket", DesigningDerobotWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :designing_derobot
  end

  plug DesigningDerobotWeb.Plugs.CORS
  plug Plug.RequestId
  plug DesigningDerobotWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug DesigningDerobotWeb.Router
end
