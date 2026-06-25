defmodule GenAI.Tool.Schema.Bool do
  @moduledoc """
  Represents a schema for boolean types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct description: nil

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Bool.is_type(%{"type" => "boolean"})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.Bool.is_type(%{"type" => "string"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "boolean"}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.Bool` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Bool.from_json(%{"type" => "boolean", "description" => "A boolean value"})
      {:ok, %GenAI.Tool.Schema.Bool{description: "A boolean value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.Bool.from_json(%{"type" => "number"})
      {:error, :unrecognized_type}
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "boolean"} = json) do
    {:ok, %__MODULE__{description: json["description"]}}
  end

  def from_json(_), do: {:error, :unrecognized_type}
end
