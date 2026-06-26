defmodule Therobotmakes.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Versioned.Descriptions.Description
end
