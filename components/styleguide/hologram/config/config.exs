import Config

config :styleguide, StyleguideWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: StyleguideWeb.ErrorHTML, json: StyleguideWeb.ErrorJSON], layout: false],
  pubsub_server: Styleguide.PubSub,
  live_view: [signing_salt: "styleguide_holo"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# Authentik / OIDC — enabled in runtime.exs when OIDC_CLIENT_ID is set
config :styleguide, :oidc_enabled, false
config :styleguide, :sso_domain_policies, %{}
config :styleguide, :post_login_path, "/app"
config :styleguide, :cookie_secure, false

import_config "#{config_env()}.exs"
