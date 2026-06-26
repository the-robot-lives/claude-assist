defmodule Codefresh.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Media.Asset
end
