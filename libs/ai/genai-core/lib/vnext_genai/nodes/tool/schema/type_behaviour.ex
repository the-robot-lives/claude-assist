defmodule GenAI.Tool.Schema.TypeBehaviour do
  @moduledoc """
  Tool Schema Type Behaviour
  """

  @callback is_type(map()) :: boolean
  @callback from_json(map()) :: {:ok, term} | {:error, term}
end
