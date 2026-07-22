variable "kube_config_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kube_context" {
  type    = string
  default = "noizu"
}

variable "namespace" {
  description = "Observability-tier namespace (created by this module)."
  type        = string
  default     = "platform-observability"
}

variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "node_selector" {
  type    = map(string)
  default = { "kubernetes.io/hostname" = "noizu-server" }
}

variable "init_state_path" {
  type    = string
  default = ""
}

# --- OneUptime ----------------------------------------------------------------
variable "oneuptime_image" {
  type    = string
  default = "oneuptime/app:release"
}

variable "oneuptime_probe_image" {
  type    = string
  default = "oneuptime/probe:release"
}

variable "oneuptime_domain" {
  type    = string
  default = "uptime.noizu.com"
}

variable "oneuptime_alias_domain" {
  type    = string
  default = "oneuptime.noizu.com"
}

variable "oneuptime_storage" {
  type    = string
  default = "10Gi"
}

# --- Shared data tier ---------------------------------------------------------
variable "postgres_host" {
  type    = string
  default = "infra-timescaledb.infra.svc.cluster.local"
}

variable "clickhouse_host" {
  type    = string
  default = "infra-clickhouse.infra.svc.cluster.local"
}

# --- Infisical operator config ------------------------------------------------
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

variable "infisical_resync_interval" {
  type    = number
  default = 120
}

variable "infisical_secrets_path" {
  type    = string
  default = "/observability/oneuptime"
}

variable "managed_secret_name" {
  type    = string
  default = "observability-app-secrets"
}

variable "tls_secret_name" {
  type    = string
  default = "cloudflare-tls-synced"
}

variable "registry_secrets_path" {
  type    = string
  default = "/shared/registry"
}

variable "infisical_host_api" {
  type    = string
  default = "https://infisical.noizu.com/api"
}
