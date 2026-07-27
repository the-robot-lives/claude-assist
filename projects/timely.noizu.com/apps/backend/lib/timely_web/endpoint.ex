defmodule TimelyWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :timely

  @session_options [
    store: :cookie,
    key: "_timely_key",
    signing_salt: "hologram_session",
    same_site: "Lax"
  ]

  socket "/socket", TimelyWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false

  # Style-guide CSS + Hologram client bundles
  plug Plug.Static,
    at: "/",
    from: :timely,
    gzip: false,
    only: ~w(themes css hologram favicon.ico robots.txt)

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :timely
  end

  plug TimelyWeb.Plugs.CORS
  plug Plug.RequestId
  plug TimelyWeb.Plugs.OtelLoggerMetadata
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # Hologram pages/commands BEFORE the Phoenix JSON API router
  plug Hologram.Router
  plug TimelyWeb.Router
end
