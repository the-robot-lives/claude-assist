defmodule TheRobotLearns.Versioned.Names.NameReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotLearns.Versioned.Names.Name
end
