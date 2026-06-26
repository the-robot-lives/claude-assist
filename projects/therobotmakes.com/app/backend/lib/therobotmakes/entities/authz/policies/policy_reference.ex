defmodule Therobotmakes.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Authz.Policies.Policy
end
