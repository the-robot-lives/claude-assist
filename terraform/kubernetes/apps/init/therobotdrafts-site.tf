# ---------------------------------------------------------------------------
# therobotdrafts.com (vnext) — Phoenix API + Next.js frontend (start-app scaffold).
# ---------------------------------------------------------------------------
# Deployed by hand via deploy-service/helm-upgrade (chart
# projects/therobotdrafts/vnext/app/helm/therobotdrafts); no helm_release here,
# matching the retired foryou pattern.
#
# The chart also declares an InfisicalSecret for /apps/therobotdrafts. This
# resource exists so the Secret is present *before* the app-timescaledb rollout
# that app_db_secrets_map["THEROBOTDRAFTS"] triggers — the StatefulSet mounts
# THEROBOTDRAFTS_DB_USER / _DB_PASSWORD from it with no `optional` fallback.

# App secrets (/apps/therobotdrafts) -> therobotdrafts-secrets.
resource "kubectl_manifest" "infisical_therobotdrafts_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-therobotdrafts-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "therobotdrafts-secrets"
        "app.kubernetes.io/component"  = "therobotdrafts"
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
            secretsPath = "/apps/therobotdrafts"
          }
        }
      }
      managedSecretReference = {
        secretName      = "therobotdrafts-secrets"
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
