# ---------------------------------------------------------------------------
# Terragrunt wrapper — Namecheap nameserver delegation
# ---------------------------------------------------------------------------
# Provider configured for noizu + trl accounts.
# Manages custom-nameserver delegation to Cloudflare (see nameservers.tf).
# Backend: S3/MinIO at namecheap/terraform.tfstate
#
# Apply prerequisite: the apply IP must be whitelisted in BOTH Namecheap
# accounts (Profile → Tools → API Access → Whitelisted IPs).

include "root" {
  path = find_in_parent_folders("root.hcl")
}
