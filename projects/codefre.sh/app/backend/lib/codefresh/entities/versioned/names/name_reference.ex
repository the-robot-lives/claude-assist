defmodule Codefresh.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Versioned.Names.Name
end
