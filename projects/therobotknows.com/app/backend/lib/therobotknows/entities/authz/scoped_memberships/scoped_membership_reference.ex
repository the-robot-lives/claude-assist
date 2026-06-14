defmodule Therobotknows.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotknows.Authz.ScopedMemberships.ScopedMembership
end
