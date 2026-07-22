# Read the root init module's outputs (storage class, node selector). init uses a
# local backend, so we read its state file directly.
data "terraform_remote_state" "init" {
  backend = "local"
  config = {
    path = coalesce(var.init_state_path, "${path.module}/../../init/terraform.tfstate")
  }
}

locals {
  storage_class = try(data.terraform_remote_state.init.outputs.storage_class, var.storage_class)
  node_selector = try(data.terraform_remote_state.init.outputs.node_selector, var.node_selector)
}
