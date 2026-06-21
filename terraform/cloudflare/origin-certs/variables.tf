variable "noizu_cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token for the noizu account. Needs 'SSL and Certificates: Edit' (Origin CA) plus zone read. Reuses TF_VAR_noizu_cloudflare_api_token from the zones module."
}

variable "requested_validity" {
  type        = number
  default     = 5475 # ~15 years (Cloudflare Origin CA maximum)
  description = "Certificate validity in days."
}

variable "out_dir" {
  type        = string
  default     = "../../../.secrets/tls/remote-access"
  description = "Directory (relative to this module) to write cert.pem/key.pem into — the repo's .secrets/tls/remote-access."
}
