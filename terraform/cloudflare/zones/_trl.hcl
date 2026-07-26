# ---------------------------------------------------------------------------
# Shared Terragrunt config for simple TRL-account Cloudflare zones.
# Included by each zone's terragrunt.hcl via:
#   include "zone" { path = find_in_parent_folders("_trl.hcl") }
# ---------------------------------------------------------------------------

terraform {
  source          = "${get_repo_root()}/terraform/modules/cf-zone"
  include_in_copy = ["import.tf"]
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.10"
    }
    provider "cloudflare" {
      api_token = var.trl_cloudflare_api_token
    }
    variable "trl_cloudflare_api_token" {
      type      = string
      sensitive = true
    }
  EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      backend "s3" {
        bucket = "tfstate"
        key    = "zones/${path_relative_to_include()}/terraform.tfstate"
        region = "us-east-1"
        endpoints = { s3 = "${get_env("TG_MINIO_ENDPOINT", "https://minio.noizu.com")}" }
        skip_credentials_validation = true
        skip_metadata_api_check     = true
        skip_region_validation      = true
        skip_requesting_account_id  = true
        use_path_style              = true
        use_lockfile                = true
      }
    }
  EOF
}

inputs = {
  account_id = "86b181a3a9b62eb309aa15946b87ed4d"
  server_ip  = "208.64.36.79"
}
