defmodule Codefresh.Projects.ProjectReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Projects.Project
end
