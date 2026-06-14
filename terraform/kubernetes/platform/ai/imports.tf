# ---------------------------------------------------------------------------
# One-time imports for resources that already exist in the cluster but are
# missing from Terraform state. Safe to remove after a successful apply.
# ---------------------------------------------------------------------------

import {
  to = helm_release.jupyterhub
  id = "platform-ai/jupyterhub"
}

import {
  to = helm_release.weaviate
  id = "platform-ai/weaviate"
}

import {
  to = kubernetes_ingress_v1.weaviate
  id = "platform-ai/weaviate"
}
