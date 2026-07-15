import Config

config :styleguide, StyleguideWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4500")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-styleguide-hologram-secret-key-base-at-least-64-bytes-long!!!!!!",
  watchers: []

config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
