defmodule Therobotlives.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotlives.Versioned.Descriptions.Description
end
