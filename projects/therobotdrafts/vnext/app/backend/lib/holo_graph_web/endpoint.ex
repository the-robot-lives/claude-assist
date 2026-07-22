defmodule HoloGraphWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :holo_graph

  socket "/socket", HoloGraphWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :holo_graph
  end

  plug HoloGraphWeb.Plugs.CORS
  plug Plug.RequestId
  plug HoloGraphWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug HoloGraphWeb.Router
end
