# ---------------------------------------------------------------------------
# One-time imports for resources that already exist in the cluster but are
# missing from Terraform state. Safe to remove after a successful apply.
# ---------------------------------------------------------------------------

import {
  to = module.platform_mariadb.kubernetes_config_map_v1.init[0]
  id = "platform/platform-mariadb-init"
}

import {
  to = module.platform_mongodb.kubernetes_config_map_v1.init[0]
  id = "platform/platform-mongodb-init"
}
