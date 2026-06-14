# ---------------------------------------------------------------------------
# Shared Infisical-managed secrets for the creative tier.
# ---------------------------------------------------------------------------
# Unlike the simpler app groups, creative apps each have their own secret set
# (mermaid uses envFrom; penpot/webstudio have distinct keys), so per-app
# InfisicalSecrets are created here (pulling /creative/<app> -> <app>-secrets) via
# for_each. Only the cluster-wide TLS cert and the ops.noizu.com pull secret are
# truly shared.

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

  depends_on = [kubernetes_namespace_v1.creative]
}

moved {
  from = kubectl_manifest.infisical_tls_sync
  to   = module.infisical_base.kubectl_manifest.infisical_tls_sync[0]
}

moved {
  from = kubectl_manifest.infisical_ops_pull
  to   = module.infisical_base.kubectl_manifest.infisical_ops_pull[0]
}

# Per-app InfisicalSecret: pulls /creative/<app> into <app>-secrets. Apps without
# secrets (chartdb, kroki, mydraft, plantuml) are simply absent from the set.
resource "kubectl_manifest" "infisical_app" {
  for_each = toset(var.app_secret_names)

  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-${each.key}"
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
            secretsPath = "/creative/${each.key}"
          }
        }
      }
      managedSecretReference = {
        secretName      = "${each.key}-secrets"
        secretNamespace = local.ns
        creationPolicy  = "Owner"
        template = {
          includeAllSecrets = true
        }
      }
    }
  })

  depends_on = [kubernetes_namespace_v1.creative]
}
