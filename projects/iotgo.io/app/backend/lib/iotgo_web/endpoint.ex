defmodule IotgoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :iotgo

  socket "/socket", IotgoWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :iotgo
  end

  plug IotgoWeb.Plugs.CORS
  plug Plug.RequestId
  plug IotgoWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug IotgoWeb.Router
end
