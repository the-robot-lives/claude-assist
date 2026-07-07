defmodule DesigningDerobot.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Versioned.Descriptions.Description
end
