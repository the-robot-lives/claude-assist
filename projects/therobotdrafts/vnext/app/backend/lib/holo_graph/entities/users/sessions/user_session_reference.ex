defmodule HoloGraph.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: HoloGraph.Users.Sessions.UserSession
end
