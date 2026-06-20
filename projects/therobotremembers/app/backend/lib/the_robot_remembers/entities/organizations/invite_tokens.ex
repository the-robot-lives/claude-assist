defmodule TheRobotRemembers.Organizations.InviteTokens do
  @moduledoc """
  Repo for TheRobotRemembers.Organizations.InviteToken
  """
  alias TheRobotRemembers.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
