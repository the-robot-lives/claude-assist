output "certificate_id" {
  value       = cloudflare_origin_ca_certificate.draft.id
  description = "Cloudflare Origin CA certificate id (for later revoke)."
}

output "expires_on" {
  value       = cloudflare_origin_ca_certificate.draft.expires_on
  description = "Certificate expiry."
}

output "cert_path" {
  value       = local_sensitive_file.cert.filename
  description = "Path to the written draft-cert.pem."
}

output "key_path" {
  value       = local_sensitive_file.key.filename
  description = "Path to the written draft-key.pem."
}
