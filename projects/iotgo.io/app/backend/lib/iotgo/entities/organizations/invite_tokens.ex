defmodule Iotgo.Organizations.InviteTokens do
  @moduledoc """
  Repo for Iotgo.Organizations.InviteToken
  """
  alias Iotgo.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
