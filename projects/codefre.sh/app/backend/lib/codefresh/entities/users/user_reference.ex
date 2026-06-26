defmodule Codefresh.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Users.User
end
