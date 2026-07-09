# ---------------------------------------------------------------------------
# starter.therobotlives.com — Phoenix API + Next.js frontend scaffold from
# components/start-app. Main site at starter.therobotlives.com, auth/app at
# app.starter.therobotlives.com.
# ---------------------------------------------------------------------------

# App secrets (/apps/start-app) -> startapp-secrets.
resource "kubectl_manifest" "infisical_startapp_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-startapp-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "startapp-secrets"
        "app.kubernetes.io/component"  = "start-app"
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
            secretsPath = "/apps/start-app"
          }
        }
      }
      managedSecretReference = {
        secretName      = "startapp-secrets"
        secretNamespace = kubernetes_namespace_v1.apps.metadata[0].name
        creationPolicy  = "Owner"
        secretType      = "Opaque"
        template = {
          includeAllSecrets = true
        }
      }
    }
  })

  depends_on = [kubernetes_namespace_v1.apps]
}

resource "helm_release" "start_app_site" {
  name      = "start-app"
  namespace = kubernetes_namespace_v1.apps.metadata[0].name
  chart     = var.start_app_chart_path != "" ? var.start_app_chart_path : abspath("${path.module}/../../../../components/start-app/helm/start-app")

  values = [
    yamlencode({
      domain    = var.start_app_domain
      appDomain = var.start_app_app_domain
      # appDomain is a sibling subdomain of domain (both fit the free
      # *.therobotlives.com wildcard cert), so cookies must be scoped to the
      # shared parent zone for the OIDC/session flow to work across both hosts.
      cookieDomain = ".therobotlives.com"
      replicas     = 1

      backend = {
        image = var.start_app_backend_image
        port  = 4000
        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }

      frontend = {
        image = var.start_app_frontend_image
        port  = 3000
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      migrate = {
        enabled = true
        command = ["bin/starter", "eval", "Starter.Release.migrate()"]
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      database = {
        host = "app-timescaledb.apps.svc.cluster.local"
        port = 5432
        name = "start_app"
      }

      secrets = {
        name = "startapp-secrets"
        keys = {
          dbUser            = "START_APP_DB_USER"
          dbPassword        = "START_APP_DB_PASSWORD"
          databaseUrl       = "START_APP_DATABASE_URL"
          secretKeyBase     = "START_APP_SECRET_KEY_BASE"
          guardianSecretKey = "START_APP_GUARDIAN_SECRET_KEY"
          redisUrl          = "START_APP_REDIS_URL"
          sendgridApiKey    = "START_APP_SENDGRID_API_KEY"
          oidcClientId      = "START_APP_OIDC_CLIENT_ID"
          oidcClientSecret  = "START_APP_OIDC_CLIENT_SECRET"
        }
      }

      # Auth is Authentik OIDC. startapp is a Noizu-labs internal scaffold, so
      # auto-register the noizu.com / therobotlives.com / derobot.is domains and
      # auto-approve every SSO-enabled domain (no invite needed).
      sso = {
        requireInvite      = false
        domains            = "noizu.com=oidc;therobotlives.com=oidc;derobot.is=oidc"
        autoApproveDomains = "*"
        oidc = {
          issuer = "https://auth.derobot.is/application/o/startapp"
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
        secretName = var.start_app_tls_secret_name
        infisical = {
          enabled              = true
          resyncInterval       = 300
          hostAPI              = local.infisical_base.host_api
          credentialsSecret    = local.infisical_base.credentials_secret
          credentialsNamespace = local.infisical_base.credentials_namespace
          projectSlug          = local.infisical_base.project_slug
          envSlug              = local.infisical_base.env_slug
          secretsPath          = "/apps/tls/therobotlives"
          crtKey               = "THEROBOTLIVES_TLS_CRT"
          keyKey               = "THEROBOTLIVES_TLS_KEY"
        }
      }

      sandbox = {
        enabled = false
      }
    })
  ]

  depends_on = [
    kubectl_manifest.infisical_ops_pull,
    kubectl_manifest.infisical_startapp_secrets,
    module.app_timescaledb,
    module.app_valkey,
  ]
}
