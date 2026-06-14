defmodule Therobotlives.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotlives.Authz.ScopedMemberships.ScopedMembership
end
