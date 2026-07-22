defmodule HoloGraph.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: HoloGraph.Versioned.Descriptions.Description
end
