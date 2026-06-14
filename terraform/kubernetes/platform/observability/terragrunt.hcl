# ---------------------------------------------------------------------------
# Terragrunt wrapper for the `platform/observability` stack.
# ---------------------------------------------------------------------------
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}/../..//platform/observability"

  exclude_from_copy = [
    "cluster-backup-noizu-*",
    "infra",
    "infra-services",
    "init",
    "apps",
    "docs",
  ]
}

dependencies {
  paths = ["../../init", "../../infra", "../../infra-services", "../init"]
}

inputs = {
  init_state_path = "${get_terragrunt_dir()}/../../init/terraform.tfstate"
}
