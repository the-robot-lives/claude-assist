defmodule TheRobotRemembers.Organizations.OrganizationReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotRemembers.Organizations.Organization
end
