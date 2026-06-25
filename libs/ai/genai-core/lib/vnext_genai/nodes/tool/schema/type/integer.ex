defmodule GenAI.Tool.Schema.Integer do
  @moduledoc """
  Represents a schema for integer types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct type: "integer",
            description: nil,
            minimum: nil,
            maximum: nil,
            multiple_of: nil,
            exclusive_minimum: nil,
            exclusive_maximum: nil

  @type t :: %__MODULE__{
          type: String.t(),
          description: String.t() | nil,
          minimum: integer() | nil,
          maximum: integer() | nil,
          multiple_of: integer() | nil,
          exclusive_minimum: boolean() | nil,
          exclusive_maximum: boolean() | nil
        }

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Enum.is_type(%{"type" => "integer"})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.Enum.is_type(%{"type" => "string"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "integer"}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.Integer` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Integer.from_json(%{"type" => "integer", "minimum" => 5, "description" => "An integer value"})
      {:ok, %GenAI.Tool.Schema.Integer{type: "integer", minimum: 5, description: "An integer value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.Integer.from_json(%{"type" => "number"})
      {:error, :unrecognized_type}
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "integer"} = json) do
    {:ok,
     %__MODULE__{
       type: "integer",
       description: json["description"],
       minimum: json["minimum"],
       maximum: json["maximum"],
       multiple_of: json["multipleOf"],
       exclusive_minimum: json["exclusiveMinimum"],
       exclusive_maximum: json["exclusiveMaximum"]
     }}
  end

  def from_json(_), do: {:error, :unrecognized_type}
end
