defmodule TheRobotLearns.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotLearns.Organizations.Membership
end
