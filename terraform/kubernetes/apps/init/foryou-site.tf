# ---------------------------------------------------------------------------
# foryou.therobotlives.com — Phoenix API + Next.js frontend (start-app scaffold).
# ---------------------------------------------------------------------------

# App secrets (/apps/foryou) -> foryou-secrets.
resource "kubectl_manifest" "infisical_foryou_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-foryou-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "foryou-secrets"
        "app.kubernetes.io/component"  = "foryou"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      resyncInterval = local.infisical_base.resync_interval
      hostAPI        = local.infisical_base.host_api
      authentication = {
        universalAuth = {
          credentialsRef = {
            secretName      = local.infisical_base.credentials_secret
            secretNamespace = local.infisical_base.credentials_namespace
          }
          secretsScope = {
            projectSlug = local.infisical_base.project_slug
            envSlug     = local.infisical_base.env_slug
            secretsPath = "/apps/foryou"
          }
        }
      }
      managedSecretReference = {
        secretName      = "foryou-secrets"
        secretNamespace = kubernetes_namespace_v1.apps.metadata[0].name
        creationPolicy  = "Owner"
        template = {
          includeAllSecrets = true
        }
      }
    }
  })

  depends_on = [kubernetes_namespace_v1.apps]
}

resource "helm_release" "foryou_site" {
  name      = "foryou"
  namespace = kubernetes_namespace_v1.apps.metadata[0].name
  chart     = var.foryou_chart_path != "" ? var.foryou_chart_path : abspath("${path.module}/../../../../projects/foryou.therobotlives.com/app/helm/start-app")

  values = [
    yamlencode({
      domain   = var.foryou_domain
      replicas = 1

      backend = {
        image = var.foryou_backend_image
        port  = 4000
        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }

      frontend = {
        image = var.foryou_frontend_image
        port  = 3000
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      migrate = {
        enabled = true
        command = ["bin/foryou", "eval", "Foryou.Release.migrate()"]
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      database = {
        host = "app-timescaledb.apps.svc.cluster.local"
        port = 5432
        name = "foryou"
      }

      secrets = {
        name = "foryou-secrets"
        keys = {
          dbUser            = "FORYOU_DB_USER"
          dbPassword        = "FORYOU_DB_PASSWORD"
          databaseUrl       = "FORYOU_DATABASE_URL"
          secretKeyBase     = "FORYOU_SECRET_KEY_BASE"
          guardianSecretKey = "FORYOU_GUARDIAN_SECRET_KEY"
          redisUrl          = "FORYOU_REDIS_URL"
        }
      }

      imagePullSecrets = [
        { name = "ops-registry-secret" }
      ]

      ingress = {
        enabled        = true
        className      = "nginx"
        cloudflareOnly = true
        annotations = {
          "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
          "nginx.ingress.kubernetes.io/proxy-body-size" = "10m"
        }
      }

      tls = {
        enabled    = true
        secretName = var.foryou_tls_secret_name
        infisical = {
          enabled              = true
          resyncInterval       = 300
          hostAPI              = local.infisical_base.host_api
          credentialsSecret    = local.infisical_base.credentials_secret
          credentialsNamespace = local.infisical_base.credentials_namespace
          projectSlug          = local.infisical_base.project_slug
          envSlug              = local.infisical_base.env_slug
          secretsPath          = "/apps/tls/foryou"
          crtKey               = "FORYOU_TLS_CRT"
          keyKey               = "FORYOU_TLS_KEY"
        }
      }
    })
  ]

  depends_on = [
    kubectl_manifest.infisical_ops_pull,
    kubectl_manifest.infisical_foryou_secrets,
    module.app_timescaledb,
    module.app_valkey,
  ]
}
