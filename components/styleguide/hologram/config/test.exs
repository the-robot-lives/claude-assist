import Config

config :styleguide, StyleguideWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-styleguide-hologram-secret-key-base-at-least-64-bytes-long!!!!!!",
  server: false

config :logger, level: :warning
