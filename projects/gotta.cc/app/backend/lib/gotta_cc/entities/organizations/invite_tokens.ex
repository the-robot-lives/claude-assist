defmodule GottaCc.Organizations.InviteTokens do
  @moduledoc """
  Repo for GottaCc.Organizations.InviteToken
  """
  alias GottaCc.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
