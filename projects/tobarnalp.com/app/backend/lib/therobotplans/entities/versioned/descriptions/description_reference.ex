defmodule Therobotplans.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotplans.Versioned.Descriptions.Description
end
