defmodule Foryou.Organizations.InviteTokens do
  @moduledoc """
  Repo for Foryou.Organizations.InviteToken
  """
  alias Foryou.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
