defmodule Jailbreaking.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Jailbreaking.Versioned.Descriptions.Description
end
