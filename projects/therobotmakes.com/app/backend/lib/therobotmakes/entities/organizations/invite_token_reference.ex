defmodule Therobotmakes.Organizations.InviteTokenReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Organizations.InviteToken
end
