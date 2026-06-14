output "zone_id" {
  description = "Cloudflare zone ID for therobotlives.com"
  value       = cloudflare_zone.this.id
}

output "nameservers" {
  description = "Cloudflare nameservers for therobotlives.com"
  value       = cloudflare_zone.this.name_servers
}
