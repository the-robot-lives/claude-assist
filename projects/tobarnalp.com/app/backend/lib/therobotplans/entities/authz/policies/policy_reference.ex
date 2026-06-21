defmodule Therobotplans.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotplans.Authz.Policies.Policy
end
