defmodule TheRobotRemembers.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotRemembers.Organizations.Membership
end
