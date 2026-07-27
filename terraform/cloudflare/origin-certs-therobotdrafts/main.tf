# ---------------------------------------------------------------------------
# Cloudflare Origin CA certificate for draft.therobotplans.com
#
# The therobotplans app's therobotplans.com cert is apex-only (not wildcard), so
# TRD vnext on draft.therobotplans.com needs its own origin cert. Single SAN — do
# NOT add the apex or a wildcard here; the apex cert belongs to therobotplans.
#
# Mints via Cloudflare Origin CA and writes the PEMs to the repo's file-based
# TLS convention (.secrets/tls/therobotplans/draft-{cert,key}.pem — the paths
# .infisical-secrets.yaml's apps-tls-therobotdrafts section reads), which then
# feeds Infisical -> the chart's tls-secret template.
#
# Apply is OUTWARD-FACING (creates a real Cloudflare certificate). Auth is the
# noizu API token (var.noizu_cloudflare_api_token) — needs "SSL and
# Certificates: Edit" (Origin CA). Uses LOCAL state (no backend block) so the
# private key never lands in the shared MinIO tfstate.
# ---------------------------------------------------------------------------

locals {
  host = "draft.therobotplans.com"
}

resource "tls_private_key" "draft" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "draft" {
  private_key_pem = tls_private_key.draft.private_key_pem

  subject {
    common_name = local.host
  }

  dns_names = [local.host]
}

resource "cloudflare_origin_ca_certificate" "draft" {
  csr                = tls_cert_request.draft.cert_request_pem
  hostnames          = [local.host]
  request_type       = "origin-rsa"
  requested_validity = var.requested_validity
}

resource "local_sensitive_file" "cert" {
  filename        = "${var.out_dir}/draft-cert.pem"
  content         = cloudflare_origin_ca_certificate.draft.certificate
  file_permission = "0644"
}

resource "local_sensitive_file" "key" {
  filename        = "${var.out_dir}/draft-key.pem"
  content         = tls_private_key.draft.private_key_pem
  file_permission = "0600"
}
