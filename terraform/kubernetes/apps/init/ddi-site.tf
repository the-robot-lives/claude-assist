# ---------------------------------------------------------------------------
# designing.derobot.is (slug "ddi") — Phoenix API + Next.js frontend
# (start-app scaffold). Deployed via helm-upgrade --include ddi (chart at
# projects/designing.derobot.is/helm/ddi). This TF resource only materializes
# the app Secret from Infisical so the chart's secrets.name (ddi-secrets)
# exists in-cluster.
# ---------------------------------------------------------------------------

# App secrets (/apps/ddi) -> ddi-secrets in the apps namespace.
resource "kubectl_manifest" "infisical_ddi_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-ddi-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "ddi-secrets"
        "app.kubernetes.io/component"  = "ddi"
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
            secretsPath = "/apps/ddi"
          }
        }
      }
      managedSecretReference = {
        secretName      = "ddi-secrets"
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
