defmodule ForyouWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :foryou

  socket "/socket", ForyouWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :foryou
  end

  plug ForyouWeb.Plugs.CORS
  plug Plug.RequestId
  plug ForyouWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug ForyouWeb.Router
end
