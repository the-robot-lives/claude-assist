defmodule Therobotmakes.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Users.User
end
