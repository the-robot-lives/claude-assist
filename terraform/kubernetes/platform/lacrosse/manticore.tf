# ---------------------------------------------------------------------------
# Manticore Search (lacrosse-manticore) — net-new bespoke workload.
# ---------------------------------------------------------------------------
# Single-replica search engine. strategy Recreate (RWO longhorn volume), node-
# pinned to noizu-server. Exposes the SQL protocol (9306) and HTTP/JSON API
# (9308) as a ClusterIP service. Data persists at /var/lib/manticore.
locals {
  manticore_labels = merge(local.common_labels, {
    "app.kubernetes.io/name"      = "lacrosse-manticore"
    "app.kubernetes.io/component" = "search"
  })
  manticore_selector = { "app.kubernetes.io/name" = "lacrosse-manticore" }
}

resource "kubernetes_persistent_volume_claim_v1" "manticore" {
  metadata {
    name      = "lacrosse-manticore-data"
    namespace = local.infra_ns
    labels    = local.manticore_labels
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = local.storage_class
    resources {
      requests = { storage = var.manticore_storage }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "manticore" {
  metadata {
    name      = "lacrosse-manticore"
    namespace = local.infra_ns
    labels    = local.manticore_labels
  }
  spec {
    replicas = 1
    strategy { type = "Recreate" }
    selector {
      match_labels = local.manticore_selector
    }
    template {
      metadata {
        labels = local.manticore_labels
      }
      spec {
        node_selector = local.node_selector

        container {
          name  = "manticore"
          image = var.manticore_image

          port {
            name           = "sql"
            container_port = 9306
          }
          port {
            name           = "http"
            container_port = 9308
          }

          # Raise mmap/memlock limits Manticore wants; harmless on the single
          # dedicated node.
          env {
            name  = "EXTRA_ARGS"
            value = ""
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/manticore"
          }

          resources {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "1", memory = "2Gi" }
          }

          liveness_probe {
            tcp_socket { port = 9306 }
            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 5
          }
          readiness_probe {
            tcp_socket { port = 9306 }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 3
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.manticore.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.infra]

  timeouts {
    create = "10m"
    update = "10m"
  }
}

resource "kubernetes_service_v1" "manticore" {
  metadata {
    name      = "lacrosse-manticore"
    namespace = local.infra_ns
    labels    = local.manticore_labels
  }
  spec {
    type     = "ClusterIP"
    selector = local.manticore_selector
    port {
      name        = "sql"
      port        = 9306
      target_port = 9306
    }
    port {
      name        = "http"
      port        = 9308
      target_port = 9308
    }
  }
}
