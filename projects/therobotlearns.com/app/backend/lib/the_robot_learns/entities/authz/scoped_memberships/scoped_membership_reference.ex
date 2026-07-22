defmodule TheRobotLearns.Authz.ScopedMemberships.ScopedMembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotLearns.Authz.ScopedMemberships.ScopedMembership
end
