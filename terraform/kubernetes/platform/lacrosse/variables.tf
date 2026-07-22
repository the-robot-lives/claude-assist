# --- Cluster target (auto-loaded from TF_VAR_* set by root.hcl) ----------------
variable "kube_config_path" {
  type    = string
  default = "~/.kube/noizu/config"
}

variable "kube_context" {
  type    = string
  default = "noizu"
}

variable "init_state_path" {
  type    = string
  default = ""
}

# --- Namespaces ---------------------------------------------------------------
variable "app_namespace" {
  description = "Lacrosse application namespace (holds the ingressor app; its Helm chart is deployed separately)."
  type        = string
  default     = "lacrosse"
}

variable "infra_namespace" {
  description = "Lacrosse data + observability namespace (TimescaleDB x2, Valkey, Manticore, dedicated SigNoz + OTel)."
  type        = string
  default     = "lacrosse-infra"
}

# --- Placement / storage ------------------------------------------------------
variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "node_selector" {
  type    = map(string)
  default = { "kubernetes.io/hostname" = "noizu-server" }
}

# --- TimescaleDB --------------------------------------------------------------
# Both instances use the upstream timescale/timescaledb-ha:pg14 image (NOT the
# house pg17+AGE image) and read their superuser password from a SealedSecret
# instead of Infisical.
variable "pg_image" {
  type    = string
  default = "timescale/timescaledb-ha:pg14-latest"
}

variable "pg_primary_storage" {
  type    = string
  default = "20Gi"
}

variable "pg_warehouse_storage" {
  type    = string
  default = "20Gi"
}

# --- Valkey -------------------------------------------------------------------
variable "valkey_image" {
  type    = string
  default = "valkey/valkey:8.1-alpine"
}

variable "valkey_storage" {
  type    = string
  default = "5Gi"
}

# --- Manticore ----------------------------------------------------------------
variable "manticore_image" {
  type    = string
  default = "manticoresearch/manticore:6.3.6"
}

variable "manticore_storage" {
  type    = string
  default = "10Gi"
}

# --- SigNoz -------------------------------------------------------------------
variable "signoz_chart_version" {
  description = "Pinned signoz/signoz Helm chart version (https://charts.signoz.io)."
  type        = string
  default     = "0.133.0"
}

variable "signoz_host" {
  type    = string
  default = "lacrosse-apm.noizu.com"
}

variable "signoz_storage" {
  description = "ClickHouse data PVC size for the bundled SigNoz ClickHouse."
  type        = string
  default     = "20Gi"
}

variable "tls_secret_name" {
  description = "Wildcard *.noizu.com TLS secret (synced into this namespace by tls.tf)."
  type        = string
  default     = "cloudflare-tls-synced"
}

# --- Infisical operator config (Valkey credentials only) ----------------------
# Only lacrosse-redis uses Infisical (via the existing valkey module). The
# TimescaleDB instances and SigNoz use SealedSecrets. Requires VALKEY_PASSWORD to
# exist in Infisical at infisical_valkey_secrets_path before deploy.
variable "infisical_project_slug" {
  type    = string
  default = "k8-infra"
}

variable "infisical_env_slug" {
  type    = string
  default = "prod"
}

variable "infisical_credentials_secret" {
  type    = string
  default = "universal-auth-credentials"
}

variable "infisical_credentials_namespace" {
  type    = string
  default = "infra"
}

variable "infisical_host_api" {
  type    = string
  default = "https://infisical.noizu.com/api"
}

variable "infisical_resync_interval" {
  type    = number
  default = 120
}

variable "infisical_valkey_secrets_path" {
  type    = string
  default = "/lacrosse/valkey"
}
