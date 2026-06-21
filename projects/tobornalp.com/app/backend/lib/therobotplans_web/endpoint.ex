defmodule TherobotplansWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :therobotplans

  socket "/socket", TherobotplansWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :therobotplans
  end

  plug TherobotplansWeb.Plugs.CORS
  plug Plug.RequestId
  plug TherobotplansWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug TherobotplansWeb.Router
end
