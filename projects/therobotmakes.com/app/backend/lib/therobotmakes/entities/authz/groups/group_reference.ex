defmodule Therobotmakes.Authz.Groups.GroupReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Authz.Groups.Group
end
