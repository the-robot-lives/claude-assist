defmodule GottaCc.Directory.SiteReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: GottaCc.Directory.Site
end
