defmodule Therobotlives.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotlives.Users.Sessions.UserSession
end
