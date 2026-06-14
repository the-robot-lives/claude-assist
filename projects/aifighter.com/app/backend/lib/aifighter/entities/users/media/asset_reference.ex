defmodule Aifighter.Users.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Users.Media.Asset
end
