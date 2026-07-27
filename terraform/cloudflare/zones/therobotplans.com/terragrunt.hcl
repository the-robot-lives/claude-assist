include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "zone" {
  path   = find_in_parent_folders("_trl.hcl")
  expose = true
}

inputs = {
  domain = "therobotplans.com"

  # draft.therobotplans.com -> The Robot Drafts (chart `therobotdrafts`, ns apps).
  # The apex and api. records serve the therobotplans app and are managed by the
  # module defaults above; this adds the `draft` label and the `app` host.
  extra_a_records = ["draft"]
  add_app         = true
}
