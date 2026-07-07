defmodule DesigningDerobot.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Users.User
end
