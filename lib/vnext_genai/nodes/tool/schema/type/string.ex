defmodule GenAI.Tool.Schema.String do
  @moduledoc """
  Represents a schema for string types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct type: "string",
            description: nil,
            min_length: nil,
            max_length: nil,
            pattern: nil,
            format: nil

  @type t :: %__MODULE__{
          type: String.t(),
          description: String.t() | nil,
          min_length: integer() | nil,
          max_length: integer() | nil,
          pattern: String.t() | nil,
          format: String.t() | nil
        }

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.String.is_type(%{"type" => "string"})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.String.is_type(%{"type" => "number"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "string"}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.String` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.String.from_json(%{"type" => "string", "description" => "A string value"})
      {:ok, %GenAI.Tool.Schema.String{type: "string", description: "A string value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.String.from_json(%{"type" => "number"})
      {:error, :unrecognized_type}
  """
  @spec from_json(map()) :: t()
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(attributes = %{"type" => "string"}) do
    a =
      attributes
      |> Enum.map(fn
        {"maxLength", value} -> {:max_length, value}
        {"minLength", value} -> {:min_length, value}
        {"pattern", value} -> {:pattern, value}
        {"description", value} -> {:description, value}
        {"format", value} -> {:format, value}
        {"type", value} -> {:type, value}
      end)
      |> Enum.reject(&is_nil(&1))

    {:ok, struct(__MODULE__, a)}
  end

  def from_json(_), do: {:error, :unrecognized_type}
end
