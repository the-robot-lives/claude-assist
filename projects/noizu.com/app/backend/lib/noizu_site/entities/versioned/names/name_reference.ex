defmodule NoizuSite.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Versioned.Names.Name
end
