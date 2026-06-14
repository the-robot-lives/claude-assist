defmodule Iotgo.Users.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Iotgo.Users.Media.Asset
end
