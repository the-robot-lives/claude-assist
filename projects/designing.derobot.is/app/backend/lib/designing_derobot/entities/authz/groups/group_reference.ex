defmodule DesigningDerobot.Authz.Groups.GroupReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Authz.Groups.Group
end
