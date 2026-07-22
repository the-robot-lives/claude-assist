# Per-site foryou Lists backing the listmonk → foryou cutover (US-090).
# Uses the foryou_list resource from terraform-provider-foryou (Chunk B).
# Idempotent by slug; `terraform destroy`/resource-removal archives (soft) the
# List rather than hard-deleting it (US-098). See ../README.md for the manifest.
#
#   terraform init
#   terraform apply -var "api_key=$FORYOU_API_KEY" -var "project_id=<uuid>"

terraform {
  required_providers {
    foryou = {
      source = "noizu/foryou" # local provider build; see terraform-provider-foryou/
    }
  }
}

variable "base_url" {
  type    = string
  default = "https://foryou.therobotlives.com"
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "project_id" {
  type        = string
  description = "UUID of the foryou Project that owns these Lists. Must already exist (no foryou_project resource yet)."
}

provider "foryou" {
  base_url = var.base_url
  api_key  = var.api_key
}

locals {
  email_attr = jsonencode([
    { slug = "email", name = "Email", type = "email", required = true, is_identity = true, sort_order = 0 },
  ])

  # Email-only waitlist Lists. Map key = public_slug (globally unique).
  waitlists = {
    "therobotlives-waitlist" = "The Robot Lives — Waitlist"
    "codefresh-waitlist"     = "CodeFre.sh — Waitlist" # both codefre.sh frontends share this List
    "gotta-cc-waitlist"      = "Gotta.cc — Waitlist"
    "aifighter-waitlist"     = "AI Fighter — Waitlist"
    "robots-unite-waitlist"  = "Robots Unite — Waitlist"
    "jailbreaking-waitlist"  = "Jailbreaking Site — Waitlist"
    "noizurpg-waitlist"      = "Noizu RPG — Waitlist"
    "iotgo-waitlist"         = "IoTGo — Waitlist"
  }
}

resource "foryou_list" "waitlist" {
  for_each = local.waitlists

  project_id  = var.project_id
  slug        = each.key
  public_slug = each.key
  name        = each.value
  kind        = "waitlist"
  status      = "active"
  settings    = jsonencode({ opt_in_mode = "double" })
  attributes  = local.email_attr
}

# Contact form (noizu.com) — typed attributes matching ContactModal.tsx.
resource "foryou_list" "noizu_contact" {
  project_id  = var.project_id
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
