# foryou Projects — one per portfolio site, all under var.organization_id.
# Lists (lists.tf) reference these by project_id. Map key = project slug
# (stable resource key; also the `slug` sent to the API).
# Removal soft-archives the Project rather than hard-deleting it.

locals {
  projects = {
    "therobotlives" = {
      name        = "The Robot Lives"
      description = "therobotlives.com — flagship portfolio site and waitlist."
    }
    "codefresh" = {
      name        = "codefre.sh"
      description = "codefre.sh — developer tooling site (app + web frontends share one waitlist)."
    }
    "gotta-cc" = {
      name        = "gotta.cc"
      description = "gotta.cc — human-curated web directory and waitlist."
    }
    "aifighter" = {
      name        = "AI Fighter"
      description = "aifighter.com — AI fighting game site and waitlist."
    }
    "robots-unite" = {
      name        = "Robots Unite"
      description = "robots-unite.com — community site and waitlist."
    }
    "jailbreaking" = {
      name        = "Jailbreaking"
      description = "jailbreakingsite.com — jailbreaking site and waitlist."
    }
    "noizurpg" = {
      name        = "Noizu RPG"
      description = "noizurpg.com — tabletop/RPG site and waitlist."
    }
    "iotgo" = {
      name        = "iotgo.io"
      description = "iotgo.io — IoT platform site and waitlist."
    }
    "noizu" = {
      name        = "Noizu Labs"
      description = "noizu.com — Noizu Labs corporate site and contact form."
    }
  }
}

resource "foryou_project" "this" {
  for_each = local.projects

  organization_id = var.organization_id
  slug            = each.key
  name            = each.value.name
  description     = each.value.description
  status          = "active"
  owner_user_id   = var.owner_user_id
}
