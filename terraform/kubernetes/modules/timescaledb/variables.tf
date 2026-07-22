variable "name" {
  description = "Workload/service name (e.g. platform-timescaledb)."
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy into."
  type        = string
}

variable "storage_class" {
  description = "StorageClass for the data PVC."
  type        = string
}

variable "storage_size" {
  description = "Data volume size."
  type        = string
  default     = "20Gi"
}

variable "image" {
  description = "TimescaleDB image (HA + Apache AGE build)."
  type        = string
  default     = "docker.io/noizu/timescaledb-ha-with-age:pg17.9-ts2.25.2-all-age1.7.0-r2"
}

variable "superuser" {
  description = "POSTGRES_USER (superuser)."
  type        = string
  default     = "postgres"
}

variable "database" {
  description = "Optional POSTGRES_DB to create on first init (empty = default)."
  type        = string
  default     = ""
}

variable "resources" {
  description = "Container resource requests/limits."
  type = object({
    requests = map(string)
    limits   = map(string)
  })
  default = {
    requests = { cpu = "250m", memory = "512Mi" }
    limits   = { cpu = "2", memory = "4Gi" }
  }
}

variable "labels" {
  description = "Extra labels applied to all resources."
  type        = map(string)
  default     = {}
}

variable "node_selector" {
  description = "nodeSelector pinning the pod to a node (e.g. the base node noizu-server). Empty = no constraint."
  type        = map(string)
  default     = {}
}

# --- Per-app DB provisioning (the infra/postgres.tf initdb.d pattern) --------
# When set, every <app>/init-db.sh under this dir (plus the shared _lib.sh) is
# bin-placed individually into /docker-entrypoint-initdb.d via subPath so the
# image's own baked 0xx first-boot scripts are preserved. The folder name is the
# single source of truth: it also drives the <APP>_DB_USER / <APP>_DB_PASSWORD
# env keys read from `app_db_secret_name`. Empty = extensions-only (no per-app
# DBs).
variable "initdb_scripts_dir" {
  description = "Path to an initdb.d dir containing <app>/init-db.sh + _lib.sh. Empty disables per-app provisioning."
  type        = string
  default     = ""
}

variable "app_db_secret_name" {
  description = "Secret holding the per-app <APP>_DB_USER / <APP>_DB_PASSWORD keys. Empty falls back to managed_secret_name. Ignored when app_db_secrets_map is set."
  type        = string
  default     = ""
}

variable "app_db_secrets_map" {
  description = "Map of UPPER(app_dir) to the K8s Secret name holding that app's DB_USER/DB_PASSWORD keys. When set, each app's env vars are sourced from its own secret instead of from a shared one."
  type        = map(string)
  default     = {}
}

variable "extra_extensions" {
  description = "Extra Postgres extensions to CREATE EXTENSION IF NOT EXISTS in POSTGRES_DB on first init, appended to the baked 00-extensions.sql (uuid-ossp + pgcrypto). Empty = current behaviour. e.g. [\"timescaledb\"] to enable TimescaleDB in the target database."
  type        = list(string)
  default     = []
}

# --- Secret management ------------------------------------------------------
# Two mutually exclusive credential sources:
#   * Infisical (default): set `managed_secret_name` + `infisical`; the operator
#     syncs POSTGRES_PASSWORD (and any per-app keys) into the managed Secret.
#   * Existing secret (sealed-secrets, etc.): set `existing_password_secret_name`
#     to read POSTGRES_PASSWORD from a pre-existing Secret and SKIP the Infisical
#     CR entirely. Used by stacks that manage credentials via SealedSecrets.
variable "managed_secret_name" {
  description = "Name of the Secret the Infisical operator creates. Required for the Infisical path; ignored when existing_password_secret_name is set."
  type        = string
  default     = ""
}

variable "password_key" {
  description = "Key in the managed Secret holding POSTGRES_PASSWORD."
  type        = string
  default     = "POSTGRES_PASSWORD"
}

variable "existing_password_secret_name" {
  description = "When set, read POSTGRES_PASSWORD from this pre-existing Secret and do NOT create an InfisicalSecret. Bypasses the Infisical wiring (e.g. for SealedSecret-managed credentials). Empty = use Infisical (current behaviour)."
  type        = string
  default     = ""
}

variable "existing_password_secret_key" {
  description = "Key in existing_password_secret_name holding POSTGRES_PASSWORD. Empty falls back to password_key."
  type        = string
  default     = ""
}

variable "infisical" {
  description = "Infisical operator universalAuth config + secrets scope. May be null when existing_password_secret_name is set."
  type = object({
    host_api              = string
    project_slug          = string
    env_slug              = string
    secrets_path          = string
    credentials_secret    = string
    credentials_namespace = string
    resync_interval       = number
  })
  default = null
}
