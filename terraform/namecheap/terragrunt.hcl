# ---------------------------------------------------------------------------
# Terragrunt wrapper — Namecheap nameserver delegation
# ---------------------------------------------------------------------------
# Provider configured for noizu + trl accounts.
# Manages custom-nameserver delegation to Cloudflare (see nameservers.tf).
# Backend: S3/MinIO at namecheap/terraform.tfstate
#
# Apply prerequisite: the apply IP must be whitelisted in BOTH Namecheap
# accounts (Profile → Tools → API Access → Whitelisted IPs).
#
# Namecheap API refreshes are slow and rarely needed. Keep this unit out of
# repo-wide `terragrunt run --all ...` unless explicitly requested:
#
#   TG_INCLUDE_NAMECHEAP=true terragrunt run --all plan

include "root" {
  path = find_in_parent_folders("root.hcl")
}

exclude {
  if = get_env("TG_INCLUDE_NAMECHEAP", "false") != "true"

  actions = [
    "apply",
    "destroy",
    "force-unlock",
    "import",
    "init",
    "output",
    "plan",
    "refresh",
    "show",
    "state",
    "validate",
  ]
}
