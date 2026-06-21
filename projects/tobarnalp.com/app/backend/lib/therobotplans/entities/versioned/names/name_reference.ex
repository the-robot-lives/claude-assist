defmodule Therobotplans.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotplans.Versioned.Names.Name
end
