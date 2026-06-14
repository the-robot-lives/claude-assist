include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "zone" {
  path   = find_in_parent_folders("_noizu.hcl")
  expose = true
}

inputs = {
  domain = "ailurophileanonymous.com"
}
