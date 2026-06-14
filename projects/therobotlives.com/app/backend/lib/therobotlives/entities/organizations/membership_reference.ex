defmodule Therobotlives.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotlives.Organizations.Membership
end
