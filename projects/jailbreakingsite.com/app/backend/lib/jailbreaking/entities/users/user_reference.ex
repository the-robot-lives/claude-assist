defmodule Jailbreaking.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Jailbreaking.Users.User
end
