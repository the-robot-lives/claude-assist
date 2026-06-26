defmodule Foryou.Users.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Foryou.Users.Media.Asset
end
