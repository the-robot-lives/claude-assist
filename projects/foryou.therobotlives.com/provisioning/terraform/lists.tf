# Per-site foryou Lists backing the listmonk → foryou cutover (US-090).
# Uses the foryou_list resource from terraform-provider-foryou (Chunk B).
# Each List belongs to the matching foryou_project (projects.tf). Idempotent by
# slug; resource-removal archives (soft) the List rather than hard-deleting it
# (US-098). See ../README.md for the manifest.
#
#   tofu init
#   tofu apply -var "foryou_api_key=$FORYOU_API_KEY"

locals {
  email_attr = jsonencode([
    { slug = "email", name = "Email", type = "email", required = true, is_identity = true, sort_order = 0 },
  ])

  # Email-only waitlist Lists. Map key = public_slug (globally unique).
  # `project` selects the owning foryou_project (projects.tf).
  waitlists = {
    "therobotlives-waitlist" = { name = "The Robot Lives — Waitlist", project = "therobotlives" }
    "codefresh-waitlist"     = { name = "CodeFre.sh — Waitlist", project = "codefresh" } # both codefre.sh frontends share this List
    "gotta-cc-waitlist"      = { name = "Gotta.cc — Waitlist", project = "gotta-cc" }
    "aifighter-waitlist"     = { name = "AI Fighter — Waitlist", project = "aifighter" }
    "robots-unite-waitlist"  = { name = "Robots Unite — Waitlist", project = "robots-unite" }
    "jailbreaking-waitlist"  = { name = "Jailbreaking Site — Waitlist", project = "jailbreaking" }
    "noizurpg-waitlist"      = { name = "Noizu RPG — Waitlist", project = "noizurpg" }
    "iotgo-waitlist"         = { name = "IoTGo — Waitlist", project = "iotgo" }
  }
}

resource "foryou_list" "waitlist" {
  for_each = local.waitlists

  project_id  = foryou_project.this[each.value.project].id
  slug        = each.key
  public_slug = each.key
  name        = each.value.name
  kind        = "waitlist"
  status      = "active"
  settings    = jsonencode({ opt_in_mode = "double" })
  attributes  = local.email_attr
}

# Contact form (noizu.com) — typed attributes matching ContactModal.tsx.
resource "foryou_list" "noizu_contact" {
  project_id  = foryou_project.this["noizu"].id
  slug        = "noizu-contact"
  public_slug = "noizu-contact"
  name        = "Noizu.com — Contact"
  kind        = "contact"
  status      = "active"
  settings    = jsonencode({ opt_in_mode = "single" })
  attributes = jsonencode([
    { slug = "email", name = "Email", type = "email", required = true, is_identity = true, sort_order = 0 },
    { slug = "name", name = "Name", type = "string", required = false, sort_order = 1 },
    { slug = "company", name = "Company", type = "string", required = false, sort_order = 2 },
    { slug = "project_type", name = "Project type", type = "select", required = false,
    options = ["Consulting", "Product/App", "AI/ML", "Infrastructure", "Collaboration", "Other"], sort_order = 3 },
    { slug = "budget_range", name = "Budget range", type = "select", required = false,
    options = ["<$10k", "$10–50k", "$50–100k", "$100k+", "Not sure"], sort_order = 4 },
    { slug = "timeline", name = "Timeline", type = "select", required = false,
    options = ["ASAP", "1–3 months", "3–6 months", "6+ months", "Exploring"], sort_order = 5 },
    { slug = "inquiry", name = "Inquiry", type = "text", required = false, sort_order = 6 },
  ])
}
