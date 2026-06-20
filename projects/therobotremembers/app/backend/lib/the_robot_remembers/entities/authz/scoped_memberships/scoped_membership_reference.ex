defmodule TheRobotRemembers.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotRemembers.Authz.ScopedMemberships.ScopedMembership
end
