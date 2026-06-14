defmodule Aifighter.Organizations.InviteTokenReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Organizations.InviteToken
end
