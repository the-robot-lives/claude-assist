defmodule Aifighter.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Authz.ScopedMemberships.ScopedMembership
end
