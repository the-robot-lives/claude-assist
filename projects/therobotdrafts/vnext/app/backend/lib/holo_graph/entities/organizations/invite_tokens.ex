defmodule HoloGraph.Organizations.InviteTokens do
  @moduledoc """
  Repo for HoloGraph.Organizations.InviteToken
  """
  alias HoloGraph.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
