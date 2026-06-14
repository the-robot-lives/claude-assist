# ---------------------------------------------------------------------------
# OneUptime — uptime monitoring + incident management, served at uptime.noizu.com.
# Uses the shared infra-clickhouse (25.x) and infra-timescaledb (PostgreSQL).
# A local Redis sidecar handles caching.
# ---------------------------------------------------------------------------

# --- Redis (lightweight local instance for OneUptime) ----------------------
resource "kubernetes_deployment_v1" "oneuptime_redis" {
  metadata {
    name      = "oneuptime-redis"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime-redis" })
  }
  spec {
    replicas = 1
    strategy { type = "Recreate" }
    selector {
      match_labels = { app = "oneuptime-redis" }
    }
    template {
      metadata {
        labels = merge(local.common_labels, { app = "oneuptime-redis" })
      }
      spec {
        node_selector = local.node_selector
        container {
          name  = "redis"
          image = "redis:7-alpine"
          port {
            container_port = 6379
            protocol       = "TCP"
          }
          resources {
            requests = { cpu = "50m", memory = "64Mi" }
            limits   = { cpu = "200m", memory = "128Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "oneuptime_redis" {
  metadata {
    name      = "oneuptime-redis"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime-redis" })
  }
  spec {
    type     = "ClusterIP"
    selector = { app = "oneuptime-redis" }
    port {
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }
  }
}

# --- App (API + dashboard + workers) --------------------------------------
resource "kubernetes_persistent_volume_claim_v1" "oneuptime_data" {
  metadata {
    name      = "oneuptime-data"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime" })
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = local.storage_class
    resources {
      requests = { storage = var.oneuptime_storage }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment_v1" "oneuptime" {
  metadata {
    name      = "oneuptime"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime" })
  }
  spec {
    replicas = 1
    strategy { type = "Recreate" }
    selector {
      match_labels = { app = "oneuptime" }
    }
    template {
      metadata {
        labels = merge(local.common_labels, { app = "oneuptime" })
      }
      spec {
        node_selector = local.node_selector

        init_container {
          name    = "wait-for-postgres"
          image   = "busybox:1.36"
          command = ["sh", "-c", "until nc -z ${var.postgres_host} 5432; do echo 'Waiting for PostgreSQL...'; sleep 5; done"]
        }
        init_container {
          name    = "wait-for-clickhouse"
          image   = "busybox:1.36"
          command = ["sh", "-c", "until wget -q --spider http://${var.clickhouse_host}:8123/ping 2>/dev/null; do echo 'Waiting for ClickHouse...'; sleep 5; done"]
        }
        init_container {
          name    = "wait-for-redis"
          image   = "busybox:1.36"
          command = ["sh", "-c", "until nc -z oneuptime-redis 6379; do echo 'Waiting for Redis...'; sleep 5; done"]
        }

        container {
          name  = "oneuptime"
          image = var.oneuptime_image

          port {
            name           = "http"
            container_port = 3002
            protocol       = "TCP"
          }
          port {
            name           = "otel-grpc"
            container_port = 4317
            protocol       = "TCP"
          }

          env {
            name  = "HOST"
            value = var.oneuptime_domain
          }
          env {
            name  = "HTTP_PROTOCOL"
            value = "https"
          }
          env {
            name  = "DATABASE_HOST"
            value = var.postgres_host
          }
          env {
            name  = "DATABASE_PORT"
            value = "5432"
          }
          env {
            name  = "DATABASE_NAME"
            value = "oneuptime"
          }
          env {
            name  = "CLICKHOUSE_HOST"
            value = var.clickhouse_host
          }
          env {
            name  = "CLICKHOUSE_PORT"
            value = "8123"
          }
          env {
            name  = "CLICKHOUSE_DATABASE"
            value = "oneuptime"
          }
          env {
            name  = "CLICKHOUSE_USER"
            value = "default"
          }
          env {
            name  = "REDIS_HOST"
            value = "oneuptime-redis"
          }
          env {
            name  = "REDIS_PORT"
            value = "6379"
          }
          env {
            name  = "LOG_LEVEL"
            value = "INFO"
          }
          env {
            name  = "BILLING_ENABLED"
            value = "false"
          }
          env {
            name  = "DISABLE_SIGNUP"
            value = "true"
          }
          env {
            name  = "IS_SAAS_SERVICE"
            value = "false"
          }
          env {
            name  = "TELEMETRY_ENABLED"
            value = "false"
          }
          env {
            name  = "NODE_ENV"
            value = "production"
          }

          # Secrets from Infisical-managed K8s Secret
          env {
            name = "DATABASE_USERNAME"
            value_from {
              secret_key_ref {
                name = var.managed_secret_name
                key  = "ONEUPTIME_DB_USER"
              }
            }
          }
          env {
            name = "DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.managed_secret_name
                key  = "ONEUPTIME_DB_PASSWORD"
              }
            }
          }
          env {
            name = "CLICKHOUSE_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.managed_secret_name
                key  = "ONEUPTIME_CLICKHOUSE_PASSWORD"
              }
            }
          }
          env {
            name = "ONEUPTIME_SECRET"
            value_from {
              secret_key_ref {
                name = var.managed_secret_name
                key  = "ONEUPTIME_SECRET"
              }
            }
          }
          env {
            name = "ENCRYPTION_SECRET"
            value_from {
              secret_key_ref {
                name = var.managed_secret_name
                key  = "ONEUPTIME_ENCRYPTION_SECRET"
              }
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/oneuptime"
          }

          resources {
            # The oneuptime/app:release image runs ts-node at runtime with a
            # hard-coded NODE_OPTIONS=--max-old-space-size=8096 (8GB heap) in its
            # start script, which overrides any env we set. A 2Gi limit gets the
            # process OOMKilled (exit 137) during startup, so the limit must
            # exceed the 8GB heap ceiling. The node has ~528GB, so this is safe.
            requests = { cpu = "500m", memory = "2Gi" }
            limits   = { cpu = "2000m", memory = "10Gi" }
          }

          liveness_probe {
            http_get {
              path = "/api/status"
              port = 3002
            }
            initial_delay_seconds = 120
            period_seconds        = 30
            timeout_seconds       = 10
          }
          readiness_probe {
            http_get {
              path = "/api/status"
              port = 3002
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.oneuptime_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubectl_manifest.infisical_app_secrets]
}

resource "kubernetes_service_v1" "oneuptime" {
  metadata {
    name      = "oneuptime"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime" })
  }
  spec {
    type     = "ClusterIP"
    selector = { app = "oneuptime" }
    port {
      name        = "http"
      port        = 3002
      target_port = 3002
      protocol    = "TCP"
    }
    port {
      name        = "otel-grpc"
      port        = 4317
      target_port = 4317
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "oneuptime" {
  metadata {
    name      = "oneuptime-ingress"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime" })
    annotations = merge(local.cf_annotations, {
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "50m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    })
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [var.oneuptime_domain]
      secret_name = var.tls_secret_name
    }
    rule {
      host = var.oneuptime_domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.oneuptime.metadata[0].name
              port { number = 3002 }
            }
          }
        }
      }
    }
  }
}

# --- Probe (uptime checker worker) ----------------------------------------
resource "kubernetes_deployment_v1" "oneuptime_probe" {
  metadata {
    name      = "oneuptime-probe"
    namespace = local.ns
    labels    = merge(local.common_labels, { app = "oneuptime-probe" })
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "oneuptime-probe" }
    }
    template {
      metadata {
        labels = merge(local.common_labels, { app = "oneuptime-probe" })
      }
      spec {
        node_selector = local.node_selector
        container {
          name  = "probe"
          image = var.oneuptime_probe_image

          env {
            name  = "ONEUPTIME_URL"
            value = "http://oneuptime.${local.ns}.svc.cluster.local:3002"
          }
          env {
            name  = "PROBE_NAME"
            value = "default-probe"
          }
          env {
            name  = "PROBE_MONITORING_WORKERS"
            value = "3"
          }
          env {
            name  = "PROBE_MONITOR_FETCH_LIMIT"
            value = "10"
          }
          env {
            name = "ONEUPTIME_SECRET"
            value_from {
              secret_key_ref {
                name = var.managed_secret_name
                key  = "ONEUPTIME_SECRET"
              }
            }
          }

          resources {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.oneuptime]
}
