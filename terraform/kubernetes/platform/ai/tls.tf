# ---------------------------------------------------------------------------
# Shared *.noizu.com wildcard TLS for platform-ai ingresses.
# ---------------------------------------------------------------------------
# Every platform-ai ingress (nb.noizu.com, langfuse, kitten-tts, jupyter,
# webui, ...) references the `cloudflare-tls-synced` secret for TLS.
module "infisical_base" {
  source = "../../modules/infisical-platform-base"

  namespace                       = local.ns
  labels                          = local.common_labels
  infisical_project_slug          = local.infisical_base.project_slug
  infisical_env_slug              = local.infisical_base.env_slug
  infisical_credentials_secret    = local.infisical_base.credentials_secret
  infisical_credentials_namespace = local.infisical_base.credentials_namespace
  infisical_host_api              = local.infisical_base.host_api
  enable_registry_pull            = false

  depends_on = [kubernetes_namespace_v1.ai]
}

moved {
  from = kubectl_manifest.infisical_tls_sync
  to   = module.infisical_base.kubectl_manifest.infisical_tls_sync[0]
}
