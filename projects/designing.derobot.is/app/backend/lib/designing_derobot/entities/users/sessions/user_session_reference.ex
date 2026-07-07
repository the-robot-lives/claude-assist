defmodule DesigningDerobot.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Users.Sessions.UserSession
end
