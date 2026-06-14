defmodule Aifighter.Organizations.OrganizationReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Organizations.Organization
end
