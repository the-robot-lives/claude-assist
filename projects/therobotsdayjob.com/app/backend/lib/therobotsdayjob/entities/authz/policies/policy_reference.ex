defmodule Therobotsdayjob.Authz.Policies.PolicyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotsdayjob.Authz.Policies.Policy
end
