defmodule Therobotmakes.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Organizations.Membership
end
