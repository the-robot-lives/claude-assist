defmodule Therobotknows.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotknows.Versioned.Descriptions.Description
end
