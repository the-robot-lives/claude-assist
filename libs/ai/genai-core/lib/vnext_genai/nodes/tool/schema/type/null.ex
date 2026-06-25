defmodule GenAI.Tool.Schema.Null do
  @moduledoc """
  Represents a schema for null types.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct type: "null",
            description: nil

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Null.is_type(%{"type" => "null"})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.Null.is_type(%{"type" => "string"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "null"}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.Null` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Null.from_json(%{"type" => "null", "description" => "A null value"})
      {:ok, %GenAI.Tool.Schema.Null{type: "null", description: "A null value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.Null.from_json(%{"type" => "number"})
      {:error, :unrecognized_type}
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "null"} = json) do
    {:ok,
     %__MODULE__{
       type: "null",
       description: json["description"]
     }}
  end

  def from_json(_), do: {:error, :unrecognized_type}
end
