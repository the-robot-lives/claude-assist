defmodule NoizuSite.Users.UserReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Users.User
end
