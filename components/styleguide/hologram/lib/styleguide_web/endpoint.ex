defmodule StyleguideWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :styleguide

  @session_options [
    store: :cookie,
    key: "_styleguide_key",
    signing_salt: "sg_holo_session",
    same_site: "Lax"
  ]

  plug Plug.Static,
    at: "/",
    from: :styleguide,
    gzip: false,
    only: StyleguideWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug Hologram.Router
  plug StyleguideWeb.Router
end
