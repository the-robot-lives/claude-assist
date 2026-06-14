defmodule Jailbreaking.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Jailbreaking.Authz.Policies.Policy
end
