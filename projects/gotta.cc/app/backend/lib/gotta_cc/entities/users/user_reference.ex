defmodule GottaCc.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: GottaCc.Users.User
end
