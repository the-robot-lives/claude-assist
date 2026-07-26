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

# helm_release.foryou_site retired 2026-07-27: foryou is deployed by hand via
# deploy-service/helm-upgrade (live chart start-app-0.1.2, not the path declared
# here). The InfisicalSecret above remains terraform-managed.
