defmodule Therobotknows.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotknows.Organizations.Membership
end
