defmodule Foryou.Authz.Groups.GroupReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Foryou.Authz.Groups.Group
end
