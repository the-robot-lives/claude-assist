defmodule NoizuSite.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Authz.ScopedMemberships.ScopedMembership
end
