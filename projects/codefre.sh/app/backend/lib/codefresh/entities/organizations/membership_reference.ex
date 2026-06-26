defmodule Codefresh.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Organizations.Membership
end
