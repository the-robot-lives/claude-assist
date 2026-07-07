defmodule DesigningDerobot.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Versioned.Names.Name
end
