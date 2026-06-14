defmodule Aifighter.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Versioned.Strings.String
end
