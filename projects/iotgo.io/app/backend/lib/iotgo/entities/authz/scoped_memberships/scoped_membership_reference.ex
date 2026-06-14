defmodule Iotgo.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Iotgo.Authz.ScopedMemberships.ScopedMembership
end
