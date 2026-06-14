defmodule GottaCcWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :gotta_cc

  socket "/socket", GottaCcWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :gotta_cc
  end

  plug GottaCcWeb.Plugs.CORS
  plug Plug.RequestId
  plug GottaCcWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug GottaCcWeb.Router
end
