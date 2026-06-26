defmodule Codefresh.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Authz.ScopedMemberships.ScopedMembership
end
