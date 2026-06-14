defmodule Aifighter.Organizations.InviteTokens do
  @moduledoc """
  Repo for Aifighter.Organizations.InviteToken
  """
  alias Aifighter.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
