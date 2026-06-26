defmodule Therobotmakes.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Media.Asset
end
