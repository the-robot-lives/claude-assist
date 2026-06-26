defmodule Therobotmakes.Organizations.OrganizationReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Organizations.Organization
end
