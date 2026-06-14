output "zone_id" {
  description = "Cloudflare zone ID for noizu.com"
  value       = cloudflare_zone.this.id
}

output "nameservers" {
  description = "Cloudflare nameservers for noizu.com"
  value       = cloudflare_zone.this.name_servers
}
