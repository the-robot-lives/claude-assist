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

# api.<domain> — explicit A record to the same origin as root (e.g. the API
# subdomain). Preferred over relying on the wildcard CNAME so the host resolves
# directly to the cluster ingress.
resource "cloudflare_dns_record" "api" {
  count   = var.add_api ? 1 : 0
  zone_id = cloudflare_zone.this.id
  name    = "api"
  type    = "A"
  content = var.server_ip
  proxied = var.proxied
  ttl     = 1
}

# Ad-hoc subdomain A records (see var.extra_a_records). Keyed by label so adding
# or removing one never re-indexes the others.
resource "cloudflare_dns_record" "extra" {
  for_each = var.extra_a_records
  zone_id  = cloudflare_zone.this.id
  name     = each.value
  type     = "A"
  content  = var.server_ip
  proxied  = var.proxied
  ttl      = 1
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
