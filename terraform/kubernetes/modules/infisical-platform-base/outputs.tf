output "tls_secret_name" {
  description = "Name of the managed TLS secret."
  value       = var.tls_secret_name
}

output "registry_secret_name" {
  description = "Name of the managed registry pull secret."
  value       = "ops-registry-secret"
}
