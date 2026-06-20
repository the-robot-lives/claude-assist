defmodule TheRobotRemembers.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotRemembers.Versioned.Names.Name
end
