defmodule Codefresh.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Users.Sessions.UserSession
end
