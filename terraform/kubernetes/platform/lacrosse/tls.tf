# ---------------------------------------------------------------------------
# Wildcard *.noizu.com TLS into lacrosse-infra (house convention).
# ---------------------------------------------------------------------------
# The shared wildcard cert is owned by infra-services and distributed per-
# namespace by the Infisical operator (NOT sealed — see infra/secrets/README).
# This syncs it into lacrosse-infra as `cloudflare-tls-synced` for the SigNoz
# ingress. Registry pull is disabled: every Lacrosse image is from a public
# registry (timescale/valkey/manticore/signoz), so no ops.noizu.com pull secret
# is needed.
module "tls_base" {
  source = "../../modules/infisical-platform-base"

  namespace            = local.infra_ns
  labels               = local.common_labels
  tls_secret_name      = var.tls_secret_name
  enable_tls_sync      = true
  enable_registry_pull = false

  depends_on = [kubernetes_namespace_v1.infra]
}
