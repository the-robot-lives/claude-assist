# ---------------------------------------------------------------------------
# Cloudflare Origin CA certificate for *.remote-access.noizu.com
#
# The existing *.noizu.com wildcard does NOT cover the second-level wildcard
# *.remote-access.noizu.com, so the frps ingress (apps-ns) needs its own origin
# cert. This mints one via Cloudflare Origin CA and writes the PEMs into the
# repo's file-based TLS convention (.secrets/tls/remote-access/), which then
# feeds Infisical / a sealed `remote-access-tls-synced` secret.
#
# Apply is OUTWARD-FACING (creates a real Cloudflare certificate). Auth is the
# noizu API token (var.noizu_cloudflare_api_token) — it must have "SSL and
# Certificates: Edit" (Origin CA). Uses LOCAL state (no backend block) so the
# private key never lands in the shared MinIO tfstate; the key is written to
# .secrets/tls/remote-access/ (gitignored) like every other origin cert.
# Schema verified against cloudflare provider v5.20.0.
# ---------------------------------------------------------------------------

locals {
  apex     = "remote-access.noizu.com"
  wildcard = "*.remote-access.noizu.com"
}

resource "tls_private_key" "remote_access" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "remote_access" {
  private_key_pem = tls_private_key.remote_access.private_key_pem

  subject {
    common_name = local.apex
  }

  dns_names = [local.wildcard, local.apex]
}

resource "cloudflare_origin_ca_certificate" "remote_access" {
  csr                = tls_cert_request.remote_access.cert_request_pem
  hostnames          = [local.wildcard, local.apex]
  request_type       = "origin-rsa"
  requested_validity = var.requested_validity
}

# Mirror the repo's file-based TLS convention so the cert flows through the same
# Infisical / sealed-secret pipeline as every other domain.
resource "local_sensitive_file" "cert" {
  filename        = "${var.out_dir}/cert.pem"
  content         = cloudflare_origin_ca_certificate.remote_access.certificate
  file_permission = "0644"
}

resource "local_sensitive_file" "key" {
  filename        = "${var.out_dir}/key.pem"
  content         = tls_private_key.remote_access.private_key_pem
  file_permission = "0600"
}
