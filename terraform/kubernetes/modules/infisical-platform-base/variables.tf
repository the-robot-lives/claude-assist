variable "namespace" {
  description = "Kubernetes namespace where the secrets will be created."
  type        = string
}

variable "labels" {
  description = "Common labels to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "infisical_project_slug" {
  type    = string
  default = "k8-infra"
}

variable "infisical_env_slug" {
  type    = string
  default = "prod"
}

variable "infisical_credentials_secret" {
  description = "Universal-auth machine-identity credentials secret."
  type        = string
  default     = "universal-auth-credentials"
}

variable "infisical_credentials_namespace" {
  type    = string
  default = "infra"
}

variable "infisical_host_api" {
  type    = string
  default = "https://infisical.noizu.com/api"
}

variable "tls_secret_name" {
  description = "Name for the managed TLS secret (kubernetes.io/tls)."
  type        = string
  default     = "cloudflare-tls-synced"
}

variable "tls_secrets_path" {
  description = "Infisical path for the TLS cert. Override for app-specific certs."
  type        = string
  default     = "/shared/tls"
}

variable "registry_secrets_path" {
  description = "Infisical path for the ops.noizu.com registry pull secret."
  type        = string
  default     = "/shared/registry"
}

variable "registry_email" {
  description = "Email for the docker registry auth."
  type        = string
  default     = "keith.brings@noizu.com"
}

variable "enable_tls_sync" {
  description = "Whether to create the wildcard TLS InfisicalSecret."
  type        = bool
  default     = true
}

variable "enable_registry_pull" {
  description = "Whether to create the ops.noizu.com registry pull InfisicalSecret."
  type        = bool
  default     = true
}
