defmodule Therobotmakes.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Versioned.Names.Name
end
