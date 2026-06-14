defmodule Aifighter.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Versioned.Descriptions.Description
end
