import Config

config :holo_graph, HoloGraph.Repo,
  username: System.get_env("DB_USER", "holo_graph"),
  password: System.get_env("DB_PASS", "holograph_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database:
    "#{System.get_env("DB_NAME", "holo_graph")}_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :holo_graph, HoloGraphWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-must-be-at-least-64-bytes-long-for-phoenix!!!!!!!!!!!",
  server: false

config :noizu_sendgrid,
  sandbox_enable: true

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :holo_graph, Oban, testing: :inline
