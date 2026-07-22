defmodule HoloGraph.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: HoloGraph.Versioned.Strings.String
end
