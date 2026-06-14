defmodule Aifighter.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Organizations.Membership
end
