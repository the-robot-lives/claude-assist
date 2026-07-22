defmodule TheRobotLearns.Users.Sessions.UserSessionReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: TheRobotLearns.Users.Sessions.UserSession
end
