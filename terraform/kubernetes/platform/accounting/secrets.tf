# ---------------------------------------------------------------------------
# Infisical-managed secrets. The operator syncs Infisical paths into the
# managed K8s Secrets that the workloads below consume.
# ---------------------------------------------------------------------------

# Shared TLS + ops registry pull secret via the platform-base module.
module "infisical_base" {
  source = "../../modules/infisical-platform-base"

  namespace                       = var.namespace
  infisical_project_slug          = local.infisical_base.project_slug
  infisical_env_slug              = local.infisical_base.env_slug
  infisical_credentials_secret    = local.infisical_base.credentials_secret
  infisical_credentials_namespace = local.infisical_base.credentials_namespace
  infisical_host_api              = local.infisical_base.host_api
  tls_secret_name                 = var.tls_secret_name

  depends_on = [kubernetes_namespace_v1.accounting]
}

moved {
  from = kubectl_manifest.infisical_tls_sync
  to   = module.infisical_base.kubectl_manifest.infisical_tls_sync[0]
}

moved {
  from = kubectl_manifest.infisical_ops_pull
  to   = module.infisical_base.kubectl_manifest.infisical_ops_pull[0]
}

# App secrets (/accounting) -> accounting-app-secrets.
# Keys (from Infisical): MARIADB_ROOT_PASSWORD, ERPNEXT_ADMIN_PASSWORD,
#   KIMAI_MARIADB_ROOT_PASSWORD, KIMAI_DATABASE_PASSWORD, KIMAI_ADMIN_EMAIL,
#   KIMAI_ADMIN_PASSWORD, KIMAI_APP_SECRET, SMTP_HOST, SMTP_PORT, SMTP_USER,
#   SMTP_PASSWORD, SMTP_FROM.
# A template synthesizes the Kimai DATABASE_URL from KIMAI_DATABASE_PASSWORD.
resource "kubectl_manifest" "infisical_app_secrets" {
  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-accounting-secrets"
      namespace = var.namespace
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
        secretNamespace = var.namespace
        creationPolicy  = "Owner"
        template = {
          includeAllSecrets = true
          data = {
            KIMAI_DATABASE_URL = "mysql://kimai:{{ .KIMAI_DATABASE_PASSWORD.Value }}@kimai-mariadb:3306/kimai"
          }
        }
      }
    }
  })

  depends_on = [kubernetes_namespace_v1.accounting]
}
