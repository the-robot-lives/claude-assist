defmodule GenAI.Tool.Schema.Object do
  @moduledoc """
  Represents a schema for object types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct type: "object",
            description: nil,
            properties: nil,
            min_properties: nil,
            max_properties: nil,
            property_names: nil,
            pattern_properties: nil,
            required: nil,
            additional_properties: nil

  @type t :: %__MODULE__{
          type: String.t(),
          description: String.t() | nil,
          properties: map() | nil,
          min_properties: integer() | nil,
          max_properties: integer() | nil,
          property_names: map() | nil,
          pattern_properties: map() | nil,
          required: [String.t()] | nil,
          additional_properties: boolean() | map() | nil
        }

  @doc """
  Check if json is of type

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Object.is_type(%{"type" => "object"})
      true

  ### Not of Type
      iex> GenAI.Tool.Schema.Object.is_type(%{"type" => "string"})
      false
  """
  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "object"}), do: true
  def is_type(_), do: false

  @doc """
  Convert Json map to a `GenAI.Tool.Schema.Object` struct, handling naming conventions.

  ## Examples

  ### Is of Type
      iex> GenAI.Tool.Schema.Object.from_json(%{"type" => "object", "description" => "An object value"})
      {:ok, %GenAI.Tool.Schema.Object{type: "object", description: "An object value"}}

  ### Not of Type
      iex> GenAI.Tool.Schema.Object.from_json(%{"type" => "number"})
      {:error, :unrecognized_type}
  """
  @spec from_json(map()) :: t()
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(attributes = %{"type" => "object"}) do
    a =
      attributes
      |> Enum.map(fn
        {"type", value} ->
          {:type, value}

        {"properties", nil} ->
          nil

        {"properties", value} ->
          x =
            Enum.map(
              value,
              fn {k, v} ->
                with {:ok, x} <- GenAI.Tool.Schema.Type.from_json(v) do
                  {k, x}
                else
                  error -> {k, error}
                end
              end
            )
            |> Map.new()

          {:properties, x}

        {"minProperties", value} ->
          {:min_properties, value}

        {"maxProperties", value} ->
          {:max_properties, value}

        {"propertyNames", value} ->
          {:property_names, value}

        {"patternProperties", nil} ->
          nil

        {"patternProperties", value} ->
          x =
            Enum.map(
              value,
              fn {k, v} ->
                with {:ok, x} <- GenAI.Tool.Schema.Type.from_json(v) do
                  {k, x}
                else
                  error -> {k, error}
                end
              end
            )
            |> Map.new()

          {:pattern_properties, x}

        {"required", nil} ->
          nil

        {"required", []} ->
          nil

        {"required", value} ->
          {:required, value}

        {"additionalProperties", nil} ->
          nil

        {"additionalProperties", true} ->
          {:additional_properties, true}

        {"additionalProperties", false} ->
          {:additional_properties, false}

        {"additionalProperties", value} ->
          x =
            with {:ok, x} <- GenAI.Tool.Schema.Type.from_json(value) do
              x
            end

          {:additional_properties, x}

        {"description", value} ->
          {:description, value}
      end)
      |> Enum.reject(&is_nil(&1))

    {:ok, struct(__MODULE__, a)}
  end

  def from_json(_), do: {:error, :pending}
end
