defmodule Therobotsdayjob.Organizations.MembershipReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotsdayjob.Organizations.Membership
end
