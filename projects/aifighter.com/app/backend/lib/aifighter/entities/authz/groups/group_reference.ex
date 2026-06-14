defmodule Aifighter.Authz.Groups.GroupReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Authz.Groups.Group
end
