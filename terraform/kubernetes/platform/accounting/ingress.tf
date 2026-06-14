# ---------------------------------------------------------------------------
# Ingresses (nginx class), TLS terminated with the Infisical-synced
# cloudflare-tls-synced wildcard cert.
# ---------------------------------------------------------------------------
locals {
  ingress_base_annotations = {
    "nginx.ingress.kubernetes.io/ssl-redirect"           = "true"
    "nginx.ingress.kubernetes.io/proxy-body-size"        = "50m"
    "nginx.ingress.kubernetes.io/whitelist-source-range" = "173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22,2400:cb00::/32,2606:4700::/32,2803:f800::/32,2405:b500::/32,2405:8100::/32,2a06:98c0::/29,2c0f:f248::/32"
  }
}

resource "kubernetes_ingress_v1" "erpnext" {
  metadata {
    name      = "erpnext-ingress"
    namespace = var.namespace
    annotations = merge(local.ingress_base_annotations, {
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "120"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "120"
    })
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [var.erpnext_domain]
      secret_name = var.tls_secret_name
    }
    rule {
      host = var.erpnext_domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${var.release_name}-erpnext"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.erpnext]
}

resource "kubernetes_ingress_v1" "kimai" {
  metadata {
    name      = "kimai-ingress"
    namespace = var.namespace
    annotations = merge(local.ingress_base_annotations, {
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
    })
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [var.kimai_domain]
      secret_name = var.tls_secret_name
    }
    rule {
      host = var.kimai_domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.kimai.metadata[0].name
              port {
                number = 8001
              }
            }
          }
        }
      }
    }
  }
}
