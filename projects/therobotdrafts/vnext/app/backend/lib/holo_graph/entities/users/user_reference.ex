defmodule HoloGraph.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: HoloGraph.Users.User
end
