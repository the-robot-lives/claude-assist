import Config

config :seed_helper,
  repo: TheRobotLearns.Repo

config :smart_token,
  repo: TheRobotLearns.Repo

config :the_robot_learns, TheRobotLearns.Repo,
  types: TheRobotLearns.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :the_robot_learns,
  ecto_repos: [TheRobotLearns.Repo],
  generators: [timestamp_type: :utc_datetime]

config :the_robot_learns, TheRobotLearnsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TheRobotLearnsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TheRobotLearns.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :the_robot_learns, :mail_from, {"TheRobotLearns", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :the_robot_learns, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :the_robot_learns, TheRobotLearns.Guardian,
  issuer: "the_robot_learns",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :the_robot_learns, :oidc_enabled, false
config :the_robot_learns, :saml_enabled, false
config :the_robot_learns, :google_enabled, false
config :the_robot_learns, :facebook_enabled, false
config :the_robot_learns, :github_enabled, false
config :the_robot_learns, :linkedin_enabled, false
config :the_robot_learns, :sso_require_invite, false
config :the_robot_learns, :require_invite_for_signup, false
config :the_robot_learns, :sso_domains, %{}
config :the_robot_learns, :sso_auto_approve_domains, []
config :the_robot_learns, :sso_domain_policies, %{}

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# Background jobs
config :the_robot_learns, Oban,
  repo: TheRobotLearns.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", TheRobotLearns.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :the_robot_learns, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :the_robot_learns, TheRobotLearnsWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
