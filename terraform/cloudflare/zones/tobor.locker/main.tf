resource "cloudflare_zone" "this" {
  account = { id = local.account_id }
  name    = "tobor.locker"
}

resource "cloudflare_dns_record" "root" {
  zone_id = cloudflare_zone.this.id
  name    = "tobor.locker"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  zone_id = cloudflare_zone.this.id
  name    = "www"
  type    = "CNAME"
  content = "tobor.locker"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "stage" {
  zone_id = cloudflare_zone.this.id
  name    = "stage"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

# ── NPL subdomains (explicit A records for routed hosts) ─────────────────────

locals {
  npl_subdomains = toset([
    "sessions",
    "tickets",
    "review",
    "chat",
    "assets",
    "artifacts",
    "projects",
    "wiki",
    "mockmcp",
  ])
}

resource "cloudflare_dns_record" "npl" {
  for_each = local.npl_subdomains
  zone_id  = cloudflare_zone.this.id
  name     = each.key
  type     = "A"
  content  = local.ip
  proxied  = true
  ttl      = 1
}

# ── Wildcard CNAME (catch-all for undefined subdomains) ──────────────────────

resource "cloudflare_dns_record" "wildcard" {
  zone_id = cloudflare_zone.this.id
  name    = "*"
  type    = "CNAME"
  content = "derobot.is"
  proxied = true
  ttl     = 1
}
