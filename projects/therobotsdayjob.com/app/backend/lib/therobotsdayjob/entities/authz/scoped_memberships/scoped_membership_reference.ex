defmodule Therobotsdayjob.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotsdayjob.Authz.ScopedMemberships.ScopedMembership
end
