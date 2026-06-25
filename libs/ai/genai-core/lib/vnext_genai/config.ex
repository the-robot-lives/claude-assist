defmodule GenAI.Config do
  @moduledoc """
  Module for fetching, and setting global or per process default config settings.
  """

  @spec reset(scope :: term) :: {:ok, term}
  def reset(scope \\ :global)

  def reset(scope) do
    {:ok, scope}
  end
end
