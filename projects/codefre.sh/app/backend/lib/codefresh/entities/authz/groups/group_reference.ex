defmodule Codefresh.Authz.Groups.GroupReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Authz.Groups.Group
end
