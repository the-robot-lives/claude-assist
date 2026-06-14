# ---------------------------------------------------------------------------
# Terragrunt wrapper — Cloudflare Zero Trust Access
# ---------------------------------------------------------------------------
# Access applications, groups, and policies protecting platform services.
# Outputs livebook_zta_provider_string consumed by kubernetes/infra-services.
# Backend: S3/MinIO at zero-trust/terraform.tfstate

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# This unit's Terraform references the shared modules at ../../modules
# (terraform/modules), which live OUTSIDE the unit dir. Terragrunt copies only
# the unit dir into its scratch cache, so a bare relative ../../modules source
# can't be resolved there. Point the copy root at the terraform dir (two levels
# up) and run in the cloudflare/zero-trust subdir.
terraform {
  source = "${get_terragrunt_dir()}/../..//cloudflare/zero-trust"

  exclude_from_copy = [
    "kubernetes",
    "sendgrid",
    "monitoring",
    "namecheap",
  ]
}
