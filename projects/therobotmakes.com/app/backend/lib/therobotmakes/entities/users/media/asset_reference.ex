defmodule Therobotmakes.Users.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Users.Media.Asset
end
