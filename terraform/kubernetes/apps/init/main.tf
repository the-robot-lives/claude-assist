# ---------------------------------------------------------------------------
# Apps-tier shared data services: app-valkey + app-postgres.
# ---------------------------------------------------------------------------
# Credentials are managed by Infisical (operator syncs /apps/* into the managed
# Secrets). Requires the infisical operator + universal-auth-credentials.
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = var.namespace
  }
}

module "app_valkey" {
  source = "../../modules/valkey"

  name                = "app-valkey"
  namespace           = kubernetes_namespace_v1.apps.metadata[0].name
  storage_class       = local.storage_class
  managed_secret_name = "app-valkey-secrets"

  infisical = merge(local.infisical_base, { secrets_path = "/apps/valkey" })
}

module "app_timescaledb" {
  source = "../../modules/timescaledb"

  name                = "app-postgres"
  namespace           = kubernetes_namespace_v1.apps.metadata[0].name
  storage_class       = local.storage_class
  managed_secret_name = "app-postgres-secrets"

  initdb_scripts_dir = "${path.module}/files/postgres/initdb.d"

  app_db_secrets_map = {
    AIFIGHTER     = "aifighter-secrets"
    CODEFRESH     = "apps-app-secrets"
    DEROBOTIS     = "derobotis-secrets"
    GOTTA_CC      = "gotta-cc-secrets"
    IOTGO         = "iotgo-secrets"
    JAILBREAKING  = "jailbreakingsite-secrets"
    NOIZU_SITE    = "noizu-site-secrets"
    START_APP     = "startapp-secrets"
    THEROBOTKNOWS = "therobotknows-secrets"
    THEROBOTLIVES = "therobotlives-secrets"
    THEROBOTPLANS = "therobotplans-secrets"
    TOBORNALP     = "tobornalp-secrets"
  }

  infisical = merge(local.infisical_base, { secrets_path = "/apps/postgres" })
}
