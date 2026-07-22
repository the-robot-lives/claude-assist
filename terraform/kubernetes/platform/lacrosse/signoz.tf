# ---------------------------------------------------------------------------
# Dedicated SigNoz (lacrosse-apm.noizu.com) — upstream signoz/signoz chart.
# ---------------------------------------------------------------------------
# A self-contained SigNoz for Lacrosse: bundled single-replica ClickHouse +
# ZooKeeper (longhorn PVCs) and the bundled OTel collector exposing OTLP
# grpc(4317)/http(4318) as a ClusterIP service (the app's ingest endpoint).
# Everything node-pinned to noizu-server, staging-sized. SigNoz keeps its own
# metadata in sqlite (postgresql subchart disabled). The UI ingress is hand-
# rolled below (chart ingress disabled) to match the house nginx/TLS convention.
#
# Chart version is pinned via var.signoz_chart_version. `helm repo add signoz
# https://charts.signoz.io` before deploy (see README).
locals {
  signoz_values = {
    global = {
      storageClass = local.storage_class
      clusterName  = "lacrosse-staging"
    }
    clusterName = "lacrosse-staging"

    # --- Bundled ClickHouse + ZooKeeper -----------------------------------
    clickhouse = {
      enabled      = true
      replicaCount = 1
      nodeSelector = local.node_selector
      persistence = {
        enabled      = true
        storageClass = local.storage_class
        size         = var.signoz_storage
      }
      resources = {
        requests = { cpu = "200m", memory = "1Gi" }
        limits   = { cpu = "2", memory = "4Gi" }
      }
      clickhouseOperator = {
        nodeSelector = local.node_selector
      }
      zookeeper = {
        enabled      = true
        replicaCount = 1
        nodeSelector = local.node_selector
        persistence = {
          enabled      = true
          storageClass = local.storage_class
          size         = "5Gi"
        }
        resources = {
          requests = { cpu = "100m", memory = "512Mi" }
          limits   = { cpu = "1", memory = "1Gi" }
        }
      }
    }

    # --- SigNoz app (UI + query service) ----------------------------------
    signoz = {
      replicaCount = 1
      nodeSelector = local.node_selector
      ingress      = { enabled = false } # hand-rolled below
      persistence = {
        enabled      = true
        storageClass = local.storage_class
        size         = "2Gi"
      }
      resources = {
        requests = { cpu = "200m", memory = "512Mi" }
        limits   = { cpu = "1", memory = "2Gi" }
      }
    }

    # --- Schema/telemetry migrator ----------------------------------------
    telemetryStoreMigrator = {
      nodeSelector = local.node_selector
    }

    # --- Bundled OTel collector (the app's ingest endpoint) ---------------
    otelCollector = {
      replicaCount = 1
      nodeSelector = local.node_selector
      service      = { type = "ClusterIP" }
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "1", memory = "1Gi" }
      }
    }

    # Metadata store: keep sqlite (bundled), do not stand up a Postgres.
    postgresql = { enabled = false }
  }
}

resource "helm_release" "signoz" {
  name       = "lacrosse-signoz"
  namespace  = local.infra_ns
  repository = "https://charts.signoz.io"
  chart      = "signoz"
  version    = var.signoz_chart_version

  values = [yamlencode(local.signoz_values)]

  timeout       = 900
  wait          = true
  atomic        = false
  recreate_pods = false

  depends_on = [
    kubernetes_namespace_v1.infra,
    kubectl_manifest.sealed,
  ]
}

# --- SigNoz UI ingress (house nginx/TLS convention) -------------------------
resource "kubernetes_ingress_v1" "signoz" {
  metadata {
    name      = "lacrosse-signoz-ingress"
    namespace = local.infra_ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "lacrosse-signoz" })
    # No configuration-snippet: the ingress-nginx admission webhook rejects
    # snippet directives (disabled cluster-wide since v1.9), which would silently
    # block the whole Ingress. See infra-services/signoz.tf for the same note.
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"           = "true"
      "nginx.ingress.kubernetes.io/enable-websocket"       = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size"        = "100m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"     = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"     = "300"
      "nginx.ingress.kubernetes.io/whitelist-source-range" = local.cf_ip_whitelist
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [var.signoz_host]
      secret_name = var.tls_secret_name
    }
    rule {
      host = var.signoz_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              # SigNoz chart service name: <release>-signoz on port 8080.
              name = "lacrosse-signoz"
              port { number = 8080 }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.signoz]
}
