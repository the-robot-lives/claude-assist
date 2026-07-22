# ---------------------------------------------------------------------------
# Lacrosse staging namespaces.
#   * lacrosse        — application tier (ingressor app; Helm chart deployed
#                       separately by the app team).
#   * lacrosse-infra  — data + observability tier: TimescaleDB x2, Valkey,
#                       Manticore, and a dedicated SigNoz + OTel collector.
# Both are node-pinned to noizu-server and fully separate from the shared
# data-ns / observability-ns stacks.
# ---------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_namespace
    labels = {
      "app.kubernetes.io/part-of"    = "lacrosse"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace_v1" "infra" {
  metadata {
    name = var.infra_namespace
    labels = {
      "app.kubernetes.io/part-of"    = "lacrosse"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

locals {
  app_ns   = kubernetes_namespace_v1.app.metadata[0].name
  infra_ns = kubernetes_namespace_v1.infra.metadata[0].name

  common_labels = {
    "app.kubernetes.io/part-of"    = "lacrosse"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Cloudflare fronts *.noizu.com; restrict ingress to CF edge ranges (same list
  # the other platform stacks use).
  cf_ip_whitelist = "173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22,2400:cb00::/32,2606:4700::/32,2803:f800::/32,2405:b500::/32,2405:8100::/32,2a06:98c0::/29,2c0f:f248::/32"
}
