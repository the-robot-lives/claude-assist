defmodule Therobotplans.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotplans.Authz.ScopedMemberships.ScopedMembership
end
