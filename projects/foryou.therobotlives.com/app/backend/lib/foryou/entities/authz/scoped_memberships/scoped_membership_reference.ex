defmodule Foryou.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Foryou.Authz.ScopedMemberships.ScopedMembership
end
