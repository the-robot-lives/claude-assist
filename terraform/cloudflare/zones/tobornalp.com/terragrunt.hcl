include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "zone" {
  path   = find_in_parent_folders("_trl.hcl")
  expose = true
}

inputs = {
  domain = "tobornalp.com"

  # Manage only the zone + root (imported) + an explicit app.tobornalp.com A
  # record (dashboard subdomain → same origin as root). www/stage/wildcard are
  # left unmanaged here so `plan` stays limited to root (no-op) + app (create).
  add_www      = true
  add_stage    = false
  add_wildcard = false
  add_app      = true
}
