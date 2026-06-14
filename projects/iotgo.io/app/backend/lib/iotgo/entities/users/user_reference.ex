defmodule Iotgo.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Iotgo.Users.User
end
