# ---------------------------------------------------------------------------
# Terragrunt wrapper for the `platform/lacrosse` stack.
# ---------------------------------------------------------------------------
# Dedicated Lacrosse staging stack: app namespace `lacrosse` plus the
# `lacrosse-infra` data + observability namespace (2x TimescaleDB, Valkey,
# Manticore, and a dedicated SigNoz + OTel collector). Fully separate from the
# shared data-ns / observability-ns stacks.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_terragrunt_dir()}/../..//platform/lacrosse"

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
