defmodule GottaCc.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: GottaCc.Authz.ScopedMemberships.ScopedMembership
end
