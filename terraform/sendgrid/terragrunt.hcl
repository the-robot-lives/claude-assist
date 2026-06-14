# ---------------------------------------------------------------------------
# Terragrunt wrapper — SendGrid email infrastructure
# ---------------------------------------------------------------------------
# API keys (11 infra + 20 portfolio) and DKIM domain authentication.
# Backend: S3/MinIO at sendgrid/terraform.tfstate

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# This unit's Terraform references the shared modules at ../modules
# (terraform/modules), which live OUTSIDE the unit dir. Terragrunt copies only
# the unit dir into its scratch cache, so a bare relative ../modules source
# can't be resolved there. Point the copy root at the terraform dir (one level
# up) and run in the sendgrid subdir (the // splits copy-root from run-subdir).
terraform {
  source = "${get_terragrunt_dir()}/..//sendgrid"

  exclude_from_copy = [
    "kubernetes",
    "cloudflare",
    "monitoring",
    "namecheap",
  ]

  # SendGrid's API rate-limits sender-authentication / api-key creation. With
  # default parallelism (10) the per-project module instances fire concurrently
  # and trip "rate limit exceeded". Force serial execution so only one SendGrid
  # API call is in flight at a time. The provider surfaces a Retry-After but
  # does not auto-retry, so serializing is the reliable fix.
  extra_arguments "serialize_sendgrid" {
    commands  = ["apply", "plan", "destroy", "refresh", "import"]
    arguments = ["-parallelism=1"]
  }
}
