# ---------------------------------------------------------------------------
# Lacrosse TimescaleDB instances (2x) — upstream timescale/timescaledb-ha:pg14.
# ---------------------------------------------------------------------------
# Both read their superuser password from a SealedSecret (existing_password_-
# secret_name) instead of Infisical. Node-pinned to noizu-server on longhorn.
#
#   lacrosse-pg-primary    -> db `primary_data`
#   lacrosse-pg-warehouse  -> db `datawarehouse`, with the timescaledb extension
#                             created in that DB on first init (extra_extensions).

module "pg_primary" {
  source = "../../modules/timescaledb"

  name          = "lacrosse-pg-primary"
  namespace     = local.infra_ns
  storage_class = local.storage_class
  storage_size  = var.pg_primary_storage
  node_selector = local.node_selector

  image    = var.pg_image
  database = "primary_data"

  existing_password_secret_name = "lacrosse-pg-primary-secrets"
  existing_password_secret_key  = "POSTGRES_PASSWORD"

  labels = local.common_labels

  depends_on = [kubectl_manifest.sealed]
}

module "pg_warehouse" {
  source = "../../modules/timescaledb"

  name          = "lacrosse-pg-warehouse"
  namespace     = local.infra_ns
  storage_class = local.storage_class
  storage_size  = var.pg_warehouse_storage
  node_selector = local.node_selector

  image            = var.pg_image
  database         = "datawarehouse"
  extra_extensions = ["timescaledb"]

  existing_password_secret_name = "lacrosse-pg-warehouse-secrets"
  existing_password_secret_key  = "POSTGRES_PASSWORD"

  labels = local.common_labels

  depends_on = [kubectl_manifest.sealed]
}
