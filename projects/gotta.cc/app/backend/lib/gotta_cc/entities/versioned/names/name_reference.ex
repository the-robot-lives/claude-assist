defmodule GottaCc.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: GottaCc.Versioned.Names.Name
end
