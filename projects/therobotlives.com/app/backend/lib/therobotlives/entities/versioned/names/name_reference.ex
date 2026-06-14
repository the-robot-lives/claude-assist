defmodule Therobotlives.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotlives.Versioned.Names.Name
end
