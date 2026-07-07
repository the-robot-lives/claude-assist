defmodule DesigningDerobot.Projects.ProjectReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Projects.Project
end
