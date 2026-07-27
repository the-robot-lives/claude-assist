defmodule Timely.Organizations.InviteTokens do
  @moduledoc """
  Repo for Timely.Organizations.InviteToken
  """
  alias Timely.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
