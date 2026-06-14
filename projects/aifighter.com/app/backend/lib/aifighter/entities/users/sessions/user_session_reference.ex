defmodule Aifighter.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Users.Sessions.UserSession
end
