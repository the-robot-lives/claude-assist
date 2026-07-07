defmodule DesigningDerobot.Organizations.InviteTokenReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Organizations.InviteToken
end
