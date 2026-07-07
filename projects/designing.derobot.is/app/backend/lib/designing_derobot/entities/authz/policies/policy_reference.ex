defmodule DesigningDerobot.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Authz.Policies.Policy
end
