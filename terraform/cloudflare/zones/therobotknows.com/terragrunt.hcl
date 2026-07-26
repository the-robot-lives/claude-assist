include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "zone" {
  path   = find_in_parent_folders("_trl.hcl")
  expose = true
}

inputs = {
  domain  = "therobotknows.com"
  # app.therobotknows.com — authed dashboard host; explicit A record instead of
  # the zone wildcard, which points at derobot.is and would misroute the app.
  add_app = true
  # api.therobotknows.com — API host; explicit A record instead of the zone
  # wildcard, which points at derobot.is and would misroute the api.
  add_api = true
}
