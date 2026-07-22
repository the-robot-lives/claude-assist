# Example: a user, a personal org owned by them, their membership, a form, and
# a service API key. Swap the values; `terraform import` works for each by id.

resource "foryou_user" "alice" {
  user_name  = "alice"
  email      = "alice@example.com"
  password   = "change-me-please"
  name_first = "Alice"
  name_last  = "Example"
}

resource "foryou_organization" "personal" {
  slug           = "alice-personal"
  name           = "Alice Personal"
  owner_user_id  = foryou_user.alice.id
}

resource "foryou_membership" "alice_owner" {
  organization_id = foryou_organization.personal.id
  user_id         = foryou_user.alice.id
  role            = "owner"
}

resource "foryou_form" "contact" {
  organization_id = foryou_organization.personal.id
  slug            = "contact"
  name            = "Contact Us"
  status          = "published"
  definition = jsonencode({
    fields = [
      { key = "name", label = "Name", type = "text", required = true },
      { key = "email", label = "Email", type = "email", required = true },
      { key = "message", label = "Message", type = "textarea", required = true }
    ]
  })
}

resource "foryou_api_key" "ci" {
  name           = "ci-deploy"
  owner_user_id  = foryou_user.alice.id
  scopes         = ["*"]
}
