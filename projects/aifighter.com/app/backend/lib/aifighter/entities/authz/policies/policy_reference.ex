defmodule Aifighter.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Authz.Policies.Policy
end
