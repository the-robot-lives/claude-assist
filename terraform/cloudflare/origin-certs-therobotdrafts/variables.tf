variable "trl_cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token for the TRL account (owns therobotplans.com). Needs 'SSL and Certificates: Edit' (Origin CA) plus zone read. Reuses TF_VAR_trl_cloudflare_api_token from the zones module (_trl.hcl group)."
}

variable "requested_validity" {
  type        = number
  default     = 5475 # ~15 years (Cloudflare Origin CA maximum)
  description = "Certificate validity in days."
}

variable "out_dir" {
  type        = string
  default     = "../../../.secrets/tls/therobotplans"
  description = "Directory (relative to this module) to write draft-cert.pem/draft-key.pem into — matches .infisical-secrets.yaml apps-tls-therobotdrafts file: paths."
}
