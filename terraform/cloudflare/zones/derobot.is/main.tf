resource "cloudflare_zone" "this" {
  account = { id = local.account_id }
  name    = "derobot.is"
}

# ── A Records ────────────────────────────────────────────────────────────────

resource "cloudflare_dns_record" "root" {
  zone_id = local.zone_id
  name    = "derobot.is"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "auth" {
  zone_id = local.zone_id
  name    = "auth"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "federated" {
  zone_id = local.zone_id
  name    = "federated"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "keygen" {
  zone_id = local.zone_id
  name    = "keygen"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "mcp" {
  zone_id = local.zone_id
  name    = "mcp"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

# ── CNAME Records ────────────────────────────────────────────────────────────

resource "cloudflare_dns_record" "www" {
  zone_id = local.zone_id
  name    = "www"
  type    = "CNAME"
  content = "derobot.is"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "stage" {
  zone_id = local.zone_id
  name    = "stage"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}

# ── Wildcard CNAME ───────────────────────────────────────────────────────────

resource "cloudflare_dns_record" "wildcard" {
  zone_id = local.zone_id
  name    = "*"
  type    = "CNAME"
  content = "derobot.is"
  proxied = true
  ttl     = 1
}

# ── MX Records (Namecheap email forwarding) ──────────────────────────────────

resource "cloudflare_dns_record" "mx_eforward1" {
  zone_id  = local.zone_id
  name     = "derobot.is"
  type     = "MX"
  content  = "eforward1.registrar-servers.com"
  priority = 10
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_eforward2" {
  zone_id  = local.zone_id
  name     = "derobot.is"
  type     = "MX"
  content  = "eforward2.registrar-servers.com"
  priority = 10
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_eforward3" {
  zone_id  = local.zone_id
  name     = "derobot.is"
  type     = "MX"
  content  = "eforward3.registrar-servers.com"
  priority = 10
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_eforward4" {
  zone_id  = local.zone_id
  name     = "derobot.is"
  type     = "MX"
  content  = "eforward4.registrar-servers.com"
  priority = 15
  ttl      = 1
}

resource "cloudflare_dns_record" "mx_eforward5" {
  zone_id  = local.zone_id
  name     = "derobot.is"
  type     = "MX"
  content  = "eforward5.registrar-servers.com"
  priority = 20
  ttl      = 1
}

# ── TXT Records ──────────────────────────────────────────────────────────────

resource "cloudflare_dns_record" "txt_spf" {
  zone_id = local.zone_id
  name    = "derobot.is"
  type    = "TXT"
  content = "\"v=spf1 include:spf.efwd.registrar-servers.com ~all\""
  ttl     = 1
}
