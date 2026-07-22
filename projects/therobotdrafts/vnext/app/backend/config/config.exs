import Config

config :seed_helper,
  repo: HoloGraph.Repo

config :smart_token,
  repo: HoloGraph.Repo

config :holo_graph, HoloGraph.Repo,
  types: HoloGraph.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :holo_graph,
  ecto_repos: [HoloGraph.Repo],
  generators: [timestamp_type: :utc_datetime]

config :holo_graph, HoloGraphWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: HoloGraphWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HoloGraph.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :holo_graph, :mail_from, {"HoloGraph", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :holo_graph, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :holo_graph, HoloGraph.Guardian,
  issuer: "holo_graph",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :holo_graph, :oidc_enabled, false
config :holo_graph, :saml_enabled, false
config :holo_graph, :google_enabled, false
config :holo_graph, :facebook_enabled, false
config :holo_graph, :github_enabled, false
config :holo_graph, :linkedin_enabled, false
config :holo_graph, :sso_require_invite, false
config :holo_graph, :sso_domains, %{}
config :holo_graph, :sso_auto_approve_domains, []
config :holo_graph, :sso_domain_policies, %{}

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# Background jobs
config :holo_graph, Oban,
  repo: HoloGraph.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", HoloGraph.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :holo_graph, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :holo_graph, HoloGraphWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
