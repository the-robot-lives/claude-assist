# ---------------------------------------------------------------------------
# One-time imports for resources that already exist in the cluster but are
# missing from Terraform state. Safe to remove after a successful apply.
# ---------------------------------------------------------------------------

import {
  to = kubernetes_deployment_v1.postgresql
  id = "platform-mail/postgresql"
}

import {
  to = kubernetes_service_v1.postgresql
  id = "platform-mail/postgresql"
}
