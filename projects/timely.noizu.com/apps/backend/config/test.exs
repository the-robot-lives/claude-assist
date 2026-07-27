import Config

config :timely, Timely.Repo,
  username: System.get_env("DB_USER", "timely"),
  password: System.get_env("DB_PASS", "timely_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "#{System.get_env("DB_NAME", "timely")}_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :timely, TimelyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-must-be-at-least-64-bytes-long-for-phoenix!!!!!!!!!!!",
  server: false

config :noizu_sendgrid,
  sandbox_enable: true

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :timely, Oban, testing: :inline

# Screenshot bytes go to an in-process store in tests. The double gate in
# Timely.Sync.Blobs is what the suite is actually exercising; the bytes just
# need somewhere to land that is not the network.
config :timely, Timely.Sync.Blobs, adapter: Timely.Sync.Blobs.Memory
