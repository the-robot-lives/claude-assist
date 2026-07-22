defmodule TheRobotLearns.Users.Media.AssetReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotLearns.Users.Media.Asset
end
