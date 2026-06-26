defmodule Codefresh.Organizations.InviteTokens do
  @moduledoc """
  Repo for Codefresh.Organizations.InviteToken
  """
  alias Codefresh.Organizations.InviteToken, as: Entity
  use Noizu.Repo
  def_repo(entity: Entity)
end
