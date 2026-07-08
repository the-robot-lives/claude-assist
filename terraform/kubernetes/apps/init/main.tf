# ---------------------------------------------------------------------------
# Apps-tier shared data services: app-valkey + app-timescaledb.
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

  # Named ACL user/pass pairs (in addition to the default requirepass user).
  # NoizuPromptLingo connects as the "npl" user.
  acl_users = {
    npl      = { password_key = "NPL_VALKEY_PASSWORD", rules = "~* &* +@all" }
    ddi      = { password_key = "DDI_VALKEY_PASSWORD", rules = "~* &* +@all" }
    tobornalp = { password_key = "TOBORNALP_VALKEY_PASSWORD", rules = "~* &* +@all" }
  }

  infisical = merge(local.infisical_base, { secrets_path = "/apps/valkey" })
}

module "app_timescaledb" {
  source = "../../modules/timescaledb"

  name                = "app-timescaledb"
  namespace           = kubernetes_namespace_v1.apps.metadata[0].name
  storage_class       = local.storage_class
  managed_secret_name = "app-timescaledb-secrets"

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
