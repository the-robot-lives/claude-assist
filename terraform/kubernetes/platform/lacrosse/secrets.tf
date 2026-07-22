# ---------------------------------------------------------------------------
# Sealed Secrets — encrypted secret files consumed by this stack.
# ---------------------------------------------------------------------------
# The sealed-secrets controller (kube-system/sealed-secrets-controller, chart
# 2.18.6) unseals these committed, encrypted files into real Secrets. The sealed
# files are the source of truth — Terraform only applies them, so an apply can
# never regenerate the values. Generate/refresh with ./secrets/seal-secrets.sh.
#
# Expected files in secrets/ (one SealedSecret each):
#   lacrosse-pg-primary-secrets   (POSTGRES_PASSWORD)          ns lacrosse-infra
#   lacrosse-pg-warehouse-secrets (POSTGRES_PASSWORD)          ns lacrosse-infra
#   lacrosse-signoz-secrets       (ADMIN_PASSWORD, JWT_SECRET) ns lacrosse-infra
#
# The app secret (lacrosse-ingressor-secrets, ns lacrosse) is authored as a
# PLACEHOLDER template (secrets/lacrosse-ingressor-secrets.template.yaml) and is
# intentionally NOT matched by the *.sealedsecret.yaml glob below — it must be
# filled in and sealed before external integrations work.
locals {
  sealed_secret_files = fileset("${path.module}/secrets", "*.sealedsecret.yaml")
}

data "kubectl_file_documents" "sealed" {
  for_each = local.sealed_secret_files
  content  = file("${path.module}/secrets/${each.value}")
}

resource "kubectl_manifest" "sealed" {
  for_each = {
    for item in flatten([
      for fname, doc in data.kubectl_file_documents.sealed : [
        for id, body in doc.manifests : {
          key  = "${fname}::${id}"
          body = body
        }
      ]
    ]) : item.key => item.body
  }
  yaml_body = each.value

  depends_on = [
    kubernetes_namespace_v1.infra,
    kubernetes_namespace_v1.app,
  ]
}
