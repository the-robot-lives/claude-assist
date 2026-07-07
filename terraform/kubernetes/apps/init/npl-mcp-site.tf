# ---------------------------------------------------------------------------
# NoizuPromptLingo (slug "npl-mcp") — Phoenix MCP backend + Next.js frontend
# serving tobor.locker + *.tobor.locker. Deployed via
# helm-upgrade --include npl-mcp (chart at projects/NoizuPromptLingo/helm/npl-mcp).
#
# This TF resource only materializes the app Secret from Infisical so the
# chart's backend.env.secretName (npl-mcp-secrets) exists in-cluster. It was
# previously provisioned by the retired platform/tobor-locker module; when that
# module was folded into the npl-mcp Helm chart the TLS InfisicalSecret moved
# into the chart (tls-secret.yaml) but the app-secrets CRD landed here alongside
# the other apps-tier sites (ddi, codefresh, ...).
#
# Keys synced VERBATIM from /apps/npl-mcp (includeAllSecrets) — the Deployment
# reads bare names: DATABASE_URL, SECRET_KEY_BASE, GUARDIAN_SECRET_KEY,
# AUTHENTIK_CLIENT_ID/SECRET, plus the media/LLM provider keys.
# ---------------------------------------------------------------------------

# App secrets (/apps/npl-mcp) -> npl-mcp-secrets in the apps namespace.
resource "kubectl_manifest" "infisical_npl_mcp_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-npl-mcp-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "npl-mcp-secrets"
        "app.kubernetes.io/component"  = "npl-mcp"
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
            secretsPath = "/apps/npl-mcp"
          }
        }
      }
      managedSecretReference = {
        secretName      = "npl-mcp-secrets"
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
