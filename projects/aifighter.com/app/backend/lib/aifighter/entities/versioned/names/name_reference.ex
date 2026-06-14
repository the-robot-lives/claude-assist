defmodule Aifighter.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Versioned.Names.Name
end
