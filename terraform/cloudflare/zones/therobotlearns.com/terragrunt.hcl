include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "zone" {
  path   = find_in_parent_folders("_trl.hcl")
  expose = true
}

inputs = {
  domain  = "therobotlearns.com"
  # app.therobotlearns.com — authed dashboard host; explicit A record instead of
  # the zone wildcard, which points at derobot.is and would misroute the app.
  add_app = true
}
