defmodule GottaCc.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: GottaCc.Organizations.Membership
end
