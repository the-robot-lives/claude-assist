defmodule Aifighter.Projects.ProjectReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Projects.Project
end
