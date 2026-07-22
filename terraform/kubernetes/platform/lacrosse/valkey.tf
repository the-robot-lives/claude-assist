# ---------------------------------------------------------------------------
# Lacrosse Valkey (lacrosse-redis) — via the existing valkey module.
# ---------------------------------------------------------------------------
# Per the existing module convention, the password is Infisical-managed: the
# operator syncs VALKEY_PASSWORD from `infisical_valkey_secrets_path` into the
# managed Secret `lacrosse-redis-secrets`. That Infisical path MUST hold a
# VALKEY_PASSWORD before deploy or the pod will not start.
locals {
  infisical_base = {
    host_api              = var.infisical_host_api
    project_slug          = var.infisical_project_slug
    env_slug              = var.infisical_env_slug
    credentials_secret    = var.infisical_credentials_secret
    credentials_namespace = var.infisical_credentials_namespace
    resync_interval       = var.infisical_resync_interval
    secrets_path          = var.infisical_valkey_secrets_path
  }
}

module "redis" {
  source = "../../modules/valkey"

  name                = "lacrosse-redis"
  namespace           = local.infra_ns
  storage_class       = local.storage_class
  storage_size        = var.valkey_storage
  node_selector       = local.node_selector
  image               = var.valkey_image
  managed_secret_name = "lacrosse-redis-secrets"

  labels = local.common_labels

  infisical = local.infisical_base

  depends_on = [kubernetes_namespace_v1.infra]
}
