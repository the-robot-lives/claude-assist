defmodule Jailbreaking.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Jailbreaking.Authz.ScopedMemberships.ScopedMembership
end
