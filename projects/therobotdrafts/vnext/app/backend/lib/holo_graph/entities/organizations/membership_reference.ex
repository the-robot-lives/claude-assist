defmodule HoloGraph.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: HoloGraph.Organizations.Membership
end
