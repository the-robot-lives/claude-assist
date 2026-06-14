defmodule NoizuSite.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Users.Sessions.UserSession
end
