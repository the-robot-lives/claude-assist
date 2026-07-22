import Config

config :codefresh, Codefresh.Repo,
  username: System.get_env("DB_USER", "codefresh"),
  password: System.get_env("DB_PASS") || System.get_env("DB_PASSWORD", "codefresh_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database:
    "#{System.get_env("DB_NAME", "codefresh")}_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :codefresh, CodefreshWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-must-be-at-least-64-bytes-long-for-phoenix!!!!!!!!!!!",
  server: false

config :noizu_sendgrid,
  sandbox_enable: true

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :codefresh, Oban, testing: :inline
config :codefresh, :token_store, :memory

# US-069: tests drive Codefresh.Runs.Scheduler.tick/1 directly; don't start the ticker.
config :codefresh, start_scheduler_ticker: false
