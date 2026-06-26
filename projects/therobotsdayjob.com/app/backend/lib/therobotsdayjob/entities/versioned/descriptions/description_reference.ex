defmodule Therobotsdayjob.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotsdayjob.Versioned.Descriptions.Description
end
