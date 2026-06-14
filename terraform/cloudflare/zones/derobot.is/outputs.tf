output "zone_id" {
  description = "Cloudflare zone ID for derobot.is"
  value       = cloudflare_zone.this.id
}

output "nameservers" {
  description = "Cloudflare nameservers for derobot.is"
  value       = cloudflare_zone.this.name_servers
}
