defmodule Jailbreaking.Organizations.InviteTokens do
  @moduledoc """
  Repo for Jailbreaking.Organizations.InviteToken
  """
  alias Jailbreaking.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
