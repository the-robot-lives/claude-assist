# ---------------------------------------------------------------------------
# Infisical-managed secrets. The operator syncs Infisical paths into the managed
# K8s Secrets the workloads consume.
# ---------------------------------------------------------------------------

# Shared TLS + ops registry pull secret via the platform-base module.
module "infisical_base" {
  source = "../../modules/infisical-platform-base"

  namespace                       = local.ns
  labels                          = local.common_labels
  infisical_project_slug          = local.infisical_base.project_slug
  infisical_env_slug              = local.infisical_base.env_slug
  infisical_credentials_secret    = local.infisical_base.credentials_secret
  infisical_credentials_namespace = local.infisical_base.credentials_namespace
  infisical_host_api              = local.infisical_base.host_api
  tls_secret_name                 = var.tls_secret_name
  registry_secrets_path           = var.registry_secrets_path

  depends_on = [kubernetes_namespace_v1.analytics]
}

moved {
  from = kubectl_manifest.infisical_tls_sync
  to   = module.infisical_base.kubectl_manifest.infisical_tls_sync[0]
}

moved {
  from = kubectl_manifest.infisical_ops_pull
  to   = module.infisical_base.kubectl_manifest.infisical_ops_pull[0]
}

# App secrets (/analytics) -> analytics-app-secrets.
# Keys: MATOMO_DB_PASSWORD; GROWTHBOOK_MONGODB_URI, GROWTHBOOK_JWT_SECRET, GROWTHBOOK_ENCRYPTION_KEY.
#   (MATOMO_DB_PASSWORD must match /platform/mariadb; growthbook db user in /platform/mongodb.)
resource "kubectl_manifest" "infisical_app_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-analytics-secrets"
      namespace = local.ns
      labels    = local.common_labels
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
            secretsPath = var.infisical_secrets_path
          }
        }
      }
      managedSecretReference = {
        secretName      = var.managed_secret_name
        secretNamespace = local.ns
        creationPolicy  = "Owner"
        template = {
          includeAllSecrets = true
        }
      }
    }
  })

  depends_on = [kubernetes_namespace_v1.analytics]
}
