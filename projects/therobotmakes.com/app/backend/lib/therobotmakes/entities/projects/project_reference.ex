defmodule Therobotmakes.Projects.ProjectReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Projects.Project
end
