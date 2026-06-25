defmodule GenAI.Tool.Schema.Number do
  @moduledoc """
  Represents a schema for number types, including integers and floating-point numbers.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct type: "number",
            description: nil,
            minimum: nil,
            maximum: nil,
            multiple_of: nil,
            exclusive_minimum: nil,
            exclusive_maximum: nil

  @type t :: %__MODULE__{
          type: String.t(),
          description: String.t() | nil,
          minimum: float() | nil,
          maximum: float() | nil,
          multiple_of: float() | nil,
          exclusive_minimum: boolean() | nil,
          exclusive_maximum: boolean() | nil
        }

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Number.is_type(%{"type" => "number"})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.Number.is_type(%{"type" => "string"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "number"}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.Number` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Number.from_json(%{"type" => "number", "description" => "A number value"})
      {:ok, %GenAI.Tool.Schema.Number{description: "A number value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.Number.from_json(%{"type" => "string"})
      {:error, :unrecognized_type}
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "number"} = json) do
    {:ok,
     %__MODULE__{
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
