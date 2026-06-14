terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

locals {
  auth_block = {
    universalAuth = {
      credentialsRef = {
        secretName      = var.infisical_credentials_secret
        secretNamespace = var.infisical_credentials_namespace
      }
    }
  }
}

resource "kubectl_manifest" "infisical_tls_sync" {
  count = var.enable_tls_sync ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-tls-sync"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      resyncInterval = 300
      hostAPI        = var.infisical_host_api
      authentication = merge(local.auth_block, {
        universalAuth = merge(local.auth_block.universalAuth, {
          secretsScope = {
            projectSlug = var.infisical_project_slug
            envSlug     = var.infisical_env_slug
            secretsPath = var.tls_secrets_path
          }
        })
      })
      managedSecretReference = {
        secretName      = var.tls_secret_name
        secretNamespace = var.namespace
        secretType      = "kubernetes.io/tls"
        creationPolicy  = "Owner"
        template = {
          includeAllSecrets = false
          data = {
            "tls.crt" = "{{ .TLS_CRT.Value }}"
            "tls.key" = "{{ .TLS_KEY.Value }}"
            "ca.crt"  = "{{ .CLOUDFLARE_CA_CRT.Value }}"
          }
        }
      }
    }
  })
}

resource "kubectl_manifest" "infisical_ops_pull" {
  count = var.enable_registry_pull ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "secrets.infisical.com/v1alpha1"
    kind       = "InfisicalSecret"
    metadata = {
      name      = "infisical-ops-registry"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      resyncInterval = 300
      hostAPI        = var.infisical_host_api
      authentication = merge(local.auth_block, {
        universalAuth = merge(local.auth_block.universalAuth, {
          secretsScope = {
            projectSlug = var.infisical_project_slug
            envSlug     = var.infisical_env_slug
            secretsPath = var.registry_secrets_path
          }
        })
      })
      managedSecretReference = {
        secretName      = "ops-registry-secret"
        secretNamespace = var.namespace
        secretType      = "kubernetes.io/dockerconfigjson"
        creationPolicy  = "Owner"
        template = {
          includeAllSecrets = false
          data = {
            ".dockerconfigjson" = "{{ mustToJson (dict \"auths\" (dict \"ops.noizu.com\" (dict \"username\" .OPS_REGISTRY_USER.Value \"password\" .OPS_REGISTRY_PASSWORD.Value \"email\" \"${var.registry_email}\" \"auth\" (printf \"%s:%s\" .OPS_REGISTRY_USER.Value .OPS_REGISTRY_PASSWORD.Value | b64enc)))) }}\n"
          }
        }
      }
    }
  })
}
