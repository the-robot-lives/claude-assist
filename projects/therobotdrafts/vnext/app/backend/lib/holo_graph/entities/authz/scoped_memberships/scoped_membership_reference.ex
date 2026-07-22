defmodule HoloGraph.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: HoloGraph.Authz.ScopedMemberships.ScopedMembership
end
