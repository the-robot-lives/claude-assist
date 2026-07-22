# ---------------------------------------------------------------------------
# Terragrunt wrapper — foryou management (Terraform provider)
# ---------------------------------------------------------------------------
# Declares resources in the foryou backend via the custom noizu/foryou provider
# (3rd-party/terraform-provider-foryou). The provider authenticates with an
# API key minted via `bin/foryou eval 'Foryou.Release.mint_api_key("terraform")'`.
#
# Provider discovery: dev_overrides in ~/.terraformrc points "noizu/foryou" at
# ~/.local/share/terraform/plugins (see scripts/build-provider.sh). Backend:
# S3/MinIO at foryou/terraform.tfstate.

include "root" {
  path = find_in_parent_folders("root.hcl")
}
