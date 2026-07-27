# ---------------------------------------------------------------------------
# timely.noizu.com — Phoenix + Hologram backend (single-image app; the
# backend renders the web UI itself, so there is no separate frontend secret
# consumer). TLS reuses the existing *.noizu.com wildcard (cloudflare-tls-synced)
# -- no per-domain apps-tls-timely entry is provisioned here.
# ---------------------------------------------------------------------------

# App secrets (/apps/timely) -> timely-secrets.
resource "kubectl_manifest" "infisical_timely_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-timely-secrets"
      namespace = kubernetes_namespace_v1.apps.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "timely-secrets"
        "app.kubernetes.io/component"  = "timely"
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
            secretsPath = "/apps/timely"
          }
        }
      }
      managedSecretReference = {
        secretName      = "timely-secrets"
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
