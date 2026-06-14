include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "zone" {
  path   = find_in_parent_folders("_trl.hcl")
  expose = true
}

inputs = {
  domain = "therobot.courses"
}
