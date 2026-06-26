defmodule Therobotmakes.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Users.Sessions.UserSession
end
