import Config

config :seed_helper,
  repo: TheRobotRemembers.Repo

config :smart_token,
  repo: TheRobotRemembers.Repo

config :the_robot_remembers, TheRobotRemembers.Repo,
  types: TheRobotRemembers.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid],
  # Per-connection Apache AGE session setup. The hook no-ops unless the AGE graph layer is
  # enabled (config :the_robot_remembers, :age_graph), so it is safe on DBs without AGE.
  after_connect: {TheRobotRemembers.Repo.AGE, :after_connect, []}

config :the_robot_remembers,
  ecto_repos: [TheRobotRemembers.Repo],
  generators: [timestamp_type: :utc_datetime]

config :the_robot_remembers, TheRobotRemembersWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TheRobotRemembersWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TheRobotRemembers.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :the_robot_remembers, :mail_from,
  {"TheRobotRemembers", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :the_robot_remembers, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :the_robot_remembers, TheRobotRemembers.Guardian,
  issuer: "the_robot_remembers",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :the_robot_remembers, :oidc_enabled, false
config :the_robot_remembers, :saml_enabled, false
config :the_robot_remembers, :google_enabled, false
config :the_robot_remembers, :facebook_enabled, false
config :the_robot_remembers, :github_enabled, false
config :the_robot_remembers, :linkedin_enabled, false
config :the_robot_remembers, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: TheRobotRemembersWeb.SAMLHandler

# Background jobs
config :the_robot_remembers, Oban,
  repo: TheRobotRemembers.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5, memory: 8, memory_maint: 2],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", TheRobotRemembers.Workers.CleanupWorker}
     ]}
  ]

# ── Memory engine (The Robot Remembers) ─────────────────────────
# Text embeddings (content/context/reflection/tangent) — OpenAI by default,
# behind a swappable behaviour. api_key is supplied at runtime (runtime.exs).
config :the_robot_remembers, :embeddings,
  provider: :openai,
  model: "text-embedding-3-small",
  dimensions: 1536,
  api_base: "https://api.openai.com/v1",
  api_key: nil,
  timeout_ms: 8_000

# Weaviate via noizu_weaviate (our Weaviate client). Holds the four named text vectors per
# memory (BYO/vectorizer:none). NOTE: noizu_weaviate reads `endpoint` at COMPILE time, so set
# it per-environment in config (dev here / prod.exs); the api key is runtime (runtime.exs).
config :noizu_weaviate, endpoint: System.get_env("WEAVIATE_ENDPOINT", "https://weaviate.noizu.com/")

# `enabled` gates the VectorStore — off until a Weaviate instance is actually available, so
# emotional-resonance + lexical recall work without it.
config :the_robot_remembers, :weaviate,
  enabled: false,
  class: "TrrMemory"

# Apache AGE graph projection of the association graph (see TheRobotRemembers.Memory.GraphMirror).
# `enabled` gates both the per-connection AGE session hook (Repo.AGE.after_connect/1) and every
# mirror enqueue — off until AGE is provisioned (Liquibase 031) on the target DB. AGE is a pure
# projection of `association_edges`; Postgres stays the system of record. Mirrors the Weaviate flag.
config :the_robot_remembers, :age_graph,
  enabled: false,
  graph: "trr_memory",
  min_edge_weight: 0.2

# Graph-store backend for recall + console graph ops (ADR-006/ADR-013 seam,
# TheRobotRemembers.Memory.GraphStore):
#   :cte (default) — the recursive-CTE implementations, extracted verbatim.
#   :age            — the same ops against the Apache AGE projection. Selecting :age without the AGE
#                     layer enabled raises at boot (GraphStore.validate!/0). Runtime: GRAPH_STORE=age.
config :the_robot_remembers, :graph_store, adapter: :cte

# Recall fusion / scoring knobs.
config :the_robot_remembers, :memory_recall,
  vector_weights: %{content: 1.0, context: 0.8, tangent: 0.8, reflection: 0.7},
  blend: %{semantic: 0.40, emotional: 0.30, recency: 0.15, salience: 0.15},
  rrf_k: 60,
  candidates_per_path: 50,
  default_limit: 12

# Hormone-harness baselines (Phase 0 Monitor stub returns these directly).
config :the_robot_remembers, :emotion,
  hormone_baseline: %{cortisol: 0.3, dopamine: 0.4, oxytocin: 0.4, serotonin: 0.5},
  # VAD weight vs hormone weight when building the pre-weighted 7-d vector
  vad_weight: 0.6,
  hormone_weight: 0.4

# Weaver association-linking thresholds/weights (tunable).
config :the_robot_remembers, :weaver,
  emotional_resonance_min: 0.85,
  emotional_k: 8,
  temporal_window_s: 3600,
  max_edges_per_dim: 8,
  weights: %{emotional: 0.5, temporal: 0.4, contextual: 0.4, tangent: 0.6, semantic: 0.6}

# Reinforcement deltas (Hebbian + on-recall), clamped to [0.05, 1.0].
config :the_robot_remembers, :reinforcement,
  recall_memory_boost: 0.02,
  recall_edge_boost: 0.05,
  explicit_boost: 0.1,
  denforce_penalty: 0.05,
  hebbian_initial: 0.3,
  graph_max_hops: 3,
  graph_min_edge_weight: 0.2

# MCP mount auth. Off by default (dev-open, Phase-0 behavior). When required, the /mcp mount is
# gated by a Guardian JWT (see TheRobotRemembersWeb.Plugs.MCPAuth). Runtime override in runtime.exs.
config :the_robot_remembers, :mcp_auth, required: false

# Feature flags
config :the_robot_remembers, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :the_robot_remembers, TheRobotRemembersWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
