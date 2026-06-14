# ---------------------------------------------------------------------------
# Verdaccio — private npm registry, served at npm.noizu.com.
# ---------------------------------------------------------------------------
# The htpasswd secret was migrated from SealedSecret to a Terraform-managed
# resource with ignore_changes on data. Update the htpasswd via kubectl:
#   htpasswd -nbBC 10 <user> <password> | kubectl create secret generic \
#     verdaccio-htpasswd --from-literal=htpasswd="$(cat -)" -n infra \
#     --dry-run=client -o yaml | kubectl apply -f -
#   kubectl rollout restart deployment/verdaccio -n infra

import {
  to = kubernetes_secret_v1.verdaccio_htpasswd
  id = "infra/verdaccio-htpasswd"
}

locals {
  verdaccio_host = "npm.noizu.com"
}

resource "kubernetes_persistent_volume_claim_v1" "verdaccio" {
  metadata {
    name      = "verdaccio-data"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = local.storage_class
    resources {
      requests = { storage = "20Gi" }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_config_map_v1" "verdaccio" {
  metadata {
    name      = "verdaccio-config"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
  }
  data = {
    "config.yaml" = file("${path.module}/files/verdaccio/config.yaml")
  }
}

resource "kubernetes_secret_v1" "verdaccio_htpasswd" {
  metadata {
    name      = "verdaccio-htpasswd"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
  }
  data = {
    htpasswd = var.verdaccio_htpasswd
  }
  lifecycle {
    ignore_changes = [data]
  }
}

resource "kubernetes_deployment_v1" "verdaccio" {
  metadata {
    name      = "verdaccio"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
  }
  spec {
    replicas = 1
    strategy { type = "Recreate" }
    selector {
      match_labels = { "app.kubernetes.io/name" = "verdaccio" }
    }
    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
      }
      spec {
        node_selector = local.node_selector
        init_container {
          name    = "fix-permissions"
          image   = "busybox:1.37"
          command = ["sh", "-c", "mkdir -p /verdaccio/storage/data && chown -R 10001:65533 /verdaccio/storage"]
          security_context { run_as_user = 0 }
          volume_mount {
            name       = "storage"
            mount_path = "/verdaccio/storage"
          }
        }
        container {
          name  = "verdaccio"
          image = "verdaccio/verdaccio:6.7.2"

          port {
            container_port = 4873
          }

          env {
            name  = "VERDACCIO_PORT"
            value = "4873"
          }

          volume_mount {
            name       = "storage"
            mount_path = "/verdaccio/storage"
          }
          volume_mount {
            name       = "config"
            mount_path = "/verdaccio/conf/config.yaml"
            sub_path   = "config.yaml"
          }
          volume_mount {
            name       = "htpasswd"
            mount_path = "/verdaccio/conf/htpasswd"
            sub_path   = "htpasswd"
          }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "250m", memory = "256Mi" }
          }

          liveness_probe {
            http_get {
              path = "/-/ping"
              port = 4873
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 1
          }
          readiness_probe {
            http_get {
              path = "/-/ping"
              port = 4873
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 1
          }
        }

        volume {
          name = "storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.verdaccio.metadata[0].name
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.verdaccio.metadata[0].name
          }
        }
        volume {
          name = "htpasswd"
          secret {
            secret_name = kubernetes_secret_v1.verdaccio_htpasswd.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret_v1.verdaccio_htpasswd]
}

resource "kubernetes_service_v1" "verdaccio" {
  metadata {
    name      = "verdaccio"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
  }
  spec {
    selector = { "app.kubernetes.io/name" = "verdaccio" }
    port {
      name        = "http"
      port        = 80
      target_port = 4873
    }
  }
}

resource "kubernetes_ingress_v1" "verdaccio" {
  metadata {
    name      = "verdaccio-ingress"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "verdaccio" })
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [local.verdaccio_host]
      secret_name = "cloudflare-tls-synced"
    }
    rule {
      host = local.verdaccio_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.verdaccio.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}
