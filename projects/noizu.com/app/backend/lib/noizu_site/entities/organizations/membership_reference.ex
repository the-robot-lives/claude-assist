defmodule NoizuSite.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Organizations.Membership
end
