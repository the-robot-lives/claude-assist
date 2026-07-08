resource "cloudflare_zone" "this" {
  account = { id = var.account_id }
  name    = var.domain
}

resource "cloudflare_dns_record" "root" {
  zone_id = cloudflare_zone.this.id
  name    = var.domain
  type    = "A"
  content = var.server_ip
  proxied = var.proxied
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  count   = var.add_www ? 1 : 0
  zone_id = cloudflare_zone.this.id
  name    = "www"
  type    = "CNAME"
  content = var.domain
  proxied = var.proxied
  ttl     = 1
}

resource "cloudflare_dns_record" "stage" {
  count   = var.add_stage ? 1 : 0
  zone_id = cloudflare_zone.this.id
  name    = "stage"
  type    = "A"
  content = var.server_ip
  proxied = var.proxied
  ttl     = 1
}

# app.<domain> — explicit A record to the same origin as root (e.g. the dashboard
# subdomain). Preferred over relying on the wildcard CNAME so the host resolves
# directly to the cluster ingress.
resource "cloudflare_dns_record" "app" {
  count   = var.add_app ? 1 : 0
  zone_id = cloudflare_zone.this.id
  name    = "app"
  type    = "A"
  content = var.server_ip
  proxied = var.proxied
  ttl     = 1
}

resource "cloudflare_dns_record" "wildcard" {
  count   = var.add_wildcard ? 1 : 0
  zone_id = cloudflare_zone.this.id
  name    = "*"
  type    = "CNAME"
  content = var.wildcard_target
  proxied = true
  ttl     = 1
}
