defmodule Codefresh.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Versioned.Descriptions.Description
end
