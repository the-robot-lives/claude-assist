defmodule NoizuSite.Organizations.InviteTokens do
  @moduledoc """
  Repo for NoizuSite.Organizations.InviteToken
  """
  alias NoizuSite.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
