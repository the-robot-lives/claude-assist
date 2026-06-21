# ---------------------------------------------------------------------------
# Terragrunt wrapper — Cloudflare account-level resources (API tokens).
# ---------------------------------------------------------------------------
# Manages the broad "terraform" admin API token used to drive all Cloudflare
# Terraform activity during the setup phase (to be scoped down / given an
# expiry later). Imported, not created — see README.
# Backend: S3/MinIO at account/terraform.tfstate
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}/../..//cloudflare/account"

  exclude_from_copy = [
    "kubernetes",
    "sendgrid",
    "monitoring",
    "namecheap",
  ]
}
