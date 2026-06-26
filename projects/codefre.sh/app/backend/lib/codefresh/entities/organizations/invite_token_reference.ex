defmodule Codefresh.Organizations.InviteTokenReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Organizations.InviteToken
end
