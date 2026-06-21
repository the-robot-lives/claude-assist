terraform {
  required_version = ">= 1.10"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Auth: API Token (the legacy Origin CA "Service Key" / api_user_service_key is
# deprecated by Cloudflare and stops working 2026-09-30). The token must carry
# "SSL and Certificates: Edit" (Origin CA) in addition to the DNS scopes; reuse
# the noizu account token (TF_VAR_noizu_cloudflare_api_token) used by the zones
# module, granting it that extra permission if it doesn't already have it.
# Verified against cloudflare provider v5.20.0.
provider "cloudflare" {
  api_token = var.noizu_cloudflare_api_token
}
