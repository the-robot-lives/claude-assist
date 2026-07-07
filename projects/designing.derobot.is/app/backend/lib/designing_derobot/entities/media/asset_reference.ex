defmodule DesigningDerobot.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Media.Asset
end
