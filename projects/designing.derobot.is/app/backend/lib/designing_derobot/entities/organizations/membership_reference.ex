defmodule DesigningDerobot.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Organizations.Membership
end
