defmodule Aifighter.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Users.User
end
