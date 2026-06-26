defmodule Codefresh.Organizations.OrganizationReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Organizations.Organization
end
