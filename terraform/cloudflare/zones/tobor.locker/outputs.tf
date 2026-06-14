output "zone_id" {
  description = "Cloudflare zone ID for tobor.locker"
  value       = cloudflare_zone.this.id
}

output "nameservers" {
  description = "Cloudflare nameservers for tobor.locker"
  value       = cloudflare_zone.this.name_servers
}
