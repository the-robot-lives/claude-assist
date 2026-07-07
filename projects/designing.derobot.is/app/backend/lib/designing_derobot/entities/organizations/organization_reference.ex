defmodule DesigningDerobot.Organizations.OrganizationReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Organizations.Organization
end
