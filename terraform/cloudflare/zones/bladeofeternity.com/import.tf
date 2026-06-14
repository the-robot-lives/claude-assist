import {
  to = cloudflare_zone.this
  id = "cce2fcced710801dbffae166ed6fca12"
}

import {
  to = cloudflare_dns_record.root
  id = "cce2fcced710801dbffae166ed6fca12/15670ddea3d401c683fe5b037209885d"
}

# www: proxied A record pointing to 208.64.36.79 (2023)
# TF will plan to replace this with a CNAME to the domain.
# Stale duplicate 8a26ead39fe56e3e8232dca76cc4f61a (DNS-only .80, 2015) needs manual Cloudflare cleanup.
import {
  to = cloudflare_dns_record.www[0]
  id = "cce2fcced710801dbffae166ed6fca12/a82b210c748db2b1df941be8b73e4239"
}

# stage: A record pointing to 208.64.36.79 (matches var.server_ip)
# Stale duplicate 3164b31a52b526db1ab9bc48c4b8042f (.80) needs manual Cloudflare cleanup.
import {
  to = cloudflare_dns_record.stage[0]
  id = "cce2fcced710801dbffae166ed6fca12/ed423280d1cf87b1731acfcb54ebb7b1"
}
