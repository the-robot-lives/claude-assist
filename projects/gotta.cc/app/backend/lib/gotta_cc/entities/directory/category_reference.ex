defmodule GottaCc.Directory.CategoryReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: GottaCc.Directory.Category
end
