defmodule Jailbreaking.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Jailbreaking.Organizations.Membership
end
