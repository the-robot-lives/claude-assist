# ---------------------------------------------------------------------------
# ArgoCD — GitOps CD, served at argocd.noizu.com. Upstream argo-cd chart; Dex is
# disabled (auth via Cloudflare Zero Trust). Deployed into the infra namespace,
# reusing the existing cloudflare-tls-synced wildcard cert. Server runs insecure
# behind the nginx ingress (TLS terminated at the edge).
# ---------------------------------------------------------------------------
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = local.ns
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  timeout = 900
  wait    = false

  values = [yamlencode({
    global = {
      domain = var.argocd_domain
    }

    server = {
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/ssl-redirect"           = "true"
          "nginx.ingress.kubernetes.io/proxy-body-size"        = "50m"
          "nginx.ingress.kubernetes.io/proxy-read-timeout"     = "300"
          "nginx.ingress.kubernetes.io/proxy-send-timeout"     = "300"
          "nginx.ingress.kubernetes.io/backend-protocol"       = "HTTP"
          "nginx.ingress.kubernetes.io/whitelist-source-range" = local.cloudflare_ip_whitelist
        }
        hostname = var.argocd_domain
        tls      = false
        extraTls = [{
          secretName = "cloudflare-tls-synced"
          hosts      = [var.argocd_domain]
        }]
      }
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "1000m", memory = "1Gi" }
      }
    }

    controller = {
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "1000m", memory = "1Gi" }
      }
    }

    repoServer = {
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    redis = {
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "250m", memory = "256Mi" }
      }
    }

    applicationSet = { enabled = false }
    notifications  = { enabled = false }
    dex = {
      enabled = true
      config = yamlencode({
        issuer   = "https://auth.derobot.is/application/o/argocd/"
        storage  = { type = "kubernetes", config = { inCluster = true } }
        web      = { http = "0.0.0.0:5556" }
        telemetry = { http = "0.0.0.0:5557" }
        staticClients = [
          {
            id     = var.argocd_oidc_client_id
            name   = "ArgoCD"
            secret = var.argocd_oidc_client_secret
            redirectURIs = [
              "https://${var.argocd_domain}/api/dex/callback"
            ]
          }
        ]
        connectors = [
          {
            type = "oidc"
            name = "Authentik"
            id   = "authentik"
            config = {
              issuer           = "https://auth.derobot.is"
              clientID         = var.argocd_authentik_client_id
              clientSecret     = var.argocd_authentik_client_secret
              redirectURI      = "http://localhost:5556/callback"
              requestedIDTokenClaims = {
                groups = { essential = true }
              }
            }
          }
        ]
      })
    }

    configs = {
      params = {
        "server.insecure" = true
      }
      cm = {
        url = "https://${var.argocd_domain}"
        "oidc.config" = yamlencode({
          name     = "Authentik"
          issuer   = "http://argocd-dex:5556/dex"
          clientID = var.argocd_oidc_client_id
          clientSecret = var.argocd_oidc_client_secret
          requestedScopes = ["openid", "profile", "email", "groups"]
          requestedIDTokenClaims = {
            groups = { essential = true }
          }
          logoutURL = "https://auth.derobot.is/application/o/argocd/end-session/"
        })
      }
      rbac = {
        "policy.csv" = "p, role:admin, applications, *, */*, allow\np, role:admin, repositories, *, *, allow\np, role:admin, clusters, *, *, allow\np, role:admin, accounts, *, *, allow\np, role:viewers, applications, *, */*, get\ng, authentik:admin, role:admin\ng, authentik:viewers, role:viewers"
      }
    }
  })]
}
