defmodule Therobotmakes.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Authz.ScopedMemberships.ScopedMembership
end
