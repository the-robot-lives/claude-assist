defmodule Iotgo.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Iotgo.Media.Asset
end
