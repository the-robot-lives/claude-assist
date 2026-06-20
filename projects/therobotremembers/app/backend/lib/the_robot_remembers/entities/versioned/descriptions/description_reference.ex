defmodule TheRobotRemembers.Versioned.Descriptions.DescriptionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotRemembers.Versioned.Descriptions.Description
end
