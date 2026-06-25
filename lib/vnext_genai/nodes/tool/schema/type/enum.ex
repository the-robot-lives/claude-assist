defmodule GenAI.Tool.Schema.Enum do
  @moduledoc """
  Represents a schema for enum types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct type: "string",
            description: nil,
            enum: nil

  @type t :: %__MODULE__{
          type: String.t(),
          description: String.t() | nil,
          enum: [String.t()]
        }

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Enum.is_type(%{"type" => "string", "enum" => ["value1", "value2"]})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.Enum.is_type(%{"type" => "string"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "string", "enum" => _}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.Enum` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Enum.from_json(%{"type" => "string", "enum" => ["value1", "value2"], "description" => "An enum value"})
      {:ok, %GenAI.Tool.Schema.Enum{type: "string", enum: ["value1", "value2"], description: "An enum value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.Enum.from_json(%{"type" => "number"})
      {:error, :unrecognized_type}
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "string", "enum" => _} = json) do
    %__MODULE__{
      type: "string",
      description: json["description"],
      enum: json["enum"]
    }
  end

  def from_json(_), do: {:error, :unrecognized_type}
end
