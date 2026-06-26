defmodule Codefresh.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Authz.Policies.Policy
end
