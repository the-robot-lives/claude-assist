# ---------------------------------------------------------------------------
# Namecheap → Cloudflare nameserver delegation
# ---------------------------------------------------------------------------
# Points each Namecheap-registered domain at the nameserver pair Cloudflare
# assigned to its zone. Source of truth for the NS values is the live
# Cloudflare API; the domain set is the intersection of the Cloudflare zones
# and the domains actually registered in each Namecheap account (verified via
# namecheap.domains.getList on 2026-06-25).
#
# Grouping is by registrar account (which Namecheap login owns the domain).
# Verified 1:1 with the hosting Cloudflare account — no cross-account domains.
#
# Excluded on purpose:
#   - youngcelebrities.net  : has a Cloudflare zone but is registered at neither
#                             Namecheap account (registered elsewhere).
#   - tobor.is, vibeucation.com : registered in TRL Namecheap but have no
#                                 Cloudflare zone, so nothing to delegate.
#
# PREREQUISITE: the IP running apply must be whitelisted in BOTH Namecheap
# accounts (Profile → Tools → API Access → Whitelisted IPs).
#
# mode = "OVERWRITE" makes the delegation exact; setting `nameservers`
# switches the domain to custom DNS (Cloudflare authoritative).
# ---------------------------------------------------------------------------

locals {
  # domain => [ns1, ns2] — registered in the NOIZU Namecheap account
  noizu_nameservers = {
    "aifighter.com"                     = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "ailurophileanonymous.com"          = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "app-guru.com"                      = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "bladeofeternity.com"               = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]
    "bloggerscompete.com"               = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "bookmarkflow.com"                  = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "codefre.sh"                        = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
    "elixirgenai.dev"                   = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "exllama.dev"                       = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "fantasticwingedavenger.com"        = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "gameclick.net"                     = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "gamesborn.com"                     = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "genleo.net"                        = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "gotta.cc"                          = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]
    "hirewritingexperts.com"            = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "inmateslife.com"                   = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "iotgo.io"                          = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "jailbreakingsite.com"              = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "justmcp.it.com"                    = ["brit.ns.cloudflare.com", "cody.ns.cloudflare.com"]  # pending in Cloudflare
    "justsecure.it.com"                 = ["brit.ns.cloudflare.com", "cody.ns.cloudflare.com"]  # pending in Cloudflare
    "kingofthepeople.com"               = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "leadingbanner.com"                 = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
    "malicious-gamers.com"              = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "malicious-mercenaries.com"         = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "malicious-mobbers.com"             = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
    "mangioneforsenate.com"             = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "mangioneinthewhitehouse.com"       = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "mcpjumpst.art"                     = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
    "noizu.com"                         = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]
    "noizu.ink"                         = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]
    "noizulabs.com"                     = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "noizurpg.com"                      = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "onlineemploymentopportunities.org" = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "phpconform.com"                    = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "phpspec.org"                       = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
    "preejaculationx.com"               = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "robots-unite.com"                  = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]
    "secureasfrak.com"                  = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "smah.pro"                          = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
    "symptoms-of-lymphoma.net"          = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]   # pending in Cloudflare
    "textrpg.org"                       = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"]
    "thefutureismangione.com"           = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "therobotlearns.blog"               = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "therobotlearns.to"                 = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"] # pending in Cloudflare
    "therobotlives.com"                 = ["pete.ns.cloudflare.com", "sue.ns.cloudflare.com"]
    "thismcp.codes"                     = ["guss.ns.cloudflare.com", "keyla.ns.cloudflare.com"] # pending in Cloudflare
  }

  # domain => [ns1, ns2] — registered in the TRL Namecheap account
  trl_nameservers = {
    "artificialbeingsanonymo.us" = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "bewarethetobor.com"         = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "derobot.is"                 = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.bond"              = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.codes"             = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.courses"           = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotedoesitall.com"     = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.institute"         = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotknows.com"          = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotlearns.com"         = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.live"              = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotmakes.com"          = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotplans.com"          = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotsrise.com"          = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobotstates.com"         = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.study"             = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.support"           = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.ventures"          = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "therobot.work"              = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "tobor.help"                 = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "tobor.locker"               = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "tobornalp.com"              = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
    "tobor.wiki"                 = ["betty.ns.cloudflare.com", "miles.ns.cloudflare.com"]
  }
}

resource "namecheap_domain_records" "noizu" {
  provider    = namecheap.noizu
  for_each    = local.noizu_nameservers
  domain      = each.key
  mode        = "OVERWRITE"
  nameservers = each.value
}

resource "namecheap_domain_records" "trl" {
  provider    = namecheap.trl
  for_each    = local.trl_nameservers
  domain      = each.key
  mode        = "OVERWRITE"
  nameservers = each.value
}
