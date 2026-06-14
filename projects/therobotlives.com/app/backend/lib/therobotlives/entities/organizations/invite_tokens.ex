defmodule Therobotlives.Organizations.InviteTokens do
  @moduledoc """
  Repo for Therobotlives.Organizations.InviteToken
  """
  alias Therobotlives.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
