defmodule Therobotplans.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotplans.Users.Sessions.UserSession
end
