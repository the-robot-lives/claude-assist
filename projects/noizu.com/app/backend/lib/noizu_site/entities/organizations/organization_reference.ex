defmodule NoizuSite.Organizations.OrganizationReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Organizations.Organization
end
