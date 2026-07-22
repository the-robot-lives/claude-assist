variable "foryou_host" {
  type        = string
  description = "Base URL of the foryou backend."
  default     = "https://foryou.therobotlives.com"
}

variable "foryou_api_token" {
  type        = string
  sensitive   = true
  description = "API key minted via bin/foryou eval 'Foryou.Release.mint_api_key(\"terraform\")'. Sourced from TF_VAR_foryou_api_token (.envrc.tf)."
}
