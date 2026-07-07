defmodule DesigningDerobot.Users.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Users.Media.Asset
end
