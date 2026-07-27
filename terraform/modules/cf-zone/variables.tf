variable "domain" {
  description = "Domain name for the Cloudflare zone (e.g. noizulabs.com)"
  type        = string
}

variable "account_id" {
  description = "Cloudflare account ID that owns the zone"
  type        = string
}

variable "server_ip" {
  description = "Primary server IP for the root A record"
  type        = string
}

variable "proxied" {
  description = "Whether the root A record is proxied through Cloudflare"
  type        = bool
  default     = true
}

variable "add_www" {
  description = "Whether to add a www CNAME pointing to the root domain"
  type        = bool
  default     = true
}

variable "add_stage" {
  description = "Whether to add a stage.* A record pointing to the server"
  type        = bool
  default     = true
}

variable "add_app" {
  description = "Whether to add an app.* A record pointing to the server (dashboard subdomain)"
  type        = bool
  default     = false
}

variable "add_api" {
  description = "Whether to add an api.* A record pointing to the server (API subdomain)"
  type        = bool
  default     = false
}

variable "add_wildcard" {
  description = "Whether to add a wildcard CNAME record pointing to the wildcard target"
  type        = bool
  default     = true
}

# Escape hatch for zones that host an extra app on a subdomain without needing a
# dedicated boolean per name (e.g. draft.therobotplans.com). An explicit A record
# beats the wildcard CNAME, so the host resolves straight to the cluster ingress.
variable "extra_a_records" {
  description = "Additional subdomain labels to publish as A records pointing at server_ip (e.g. [\"draft\"])"
  type        = set(string)
  default     = []
}

variable "wildcard_target" {
  description = "Target for the wildcard CNAME record"
  type        = string
  default     = "derobot.is"
}
