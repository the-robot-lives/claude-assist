defmodule Iotgo.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Iotgo.Users.Sessions.UserSession
end
