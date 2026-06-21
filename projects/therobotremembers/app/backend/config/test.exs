import Config

config :the_robot_remembers, TheRobotRemembers.Repo,
  username: System.get_env("DB_USER", "the_robot_remembers"),
  password: System.get_env("DB_PASS", "trr_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "#{System.get_env("DB_NAME", "the_robot_remembers")}_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  # Shared-mode (async: false) tests hold one connection for the whole test. The heavy memory
  # suites (1024-memory scale write, 172-memory sim load) can run >15s once the BEAM is under
  # load from a prior test, tripping the default 15s ownership/checkout timeout and disconnecting
  # the owner (→ spurious OwnershipError in the *next* query). Give them ample headroom.
  ownership_timeout: 120_000,
  timeout: 120_000

config :the_robot_remembers, TheRobotRemembersWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key-base-must-be-at-least-64-bytes-long-for-phoenix!!!!!!!!!!!",
  server: false

config :noizu_sendgrid,
  sandbox_enable: true

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :the_robot_remembers, Oban, testing: :inline

# Run memory side-effect workers synchronously in the test process (see TheRobotRemembers.Jobs).
# Bypasses Oban's executor, which corrupts the shared Ecto Sandbox connection under load.
config :the_robot_remembers, :jobs_mode, :sync
