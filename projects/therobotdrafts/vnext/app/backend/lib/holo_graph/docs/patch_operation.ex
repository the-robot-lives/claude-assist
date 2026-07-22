defmodule HoloGraph.Docs.PatchOperation do
  @moduledoc """
  Contract type for graph document patch operations.

  This is intentionally persistence-agnostic. It gives the frontend and future
  collab pipeline a stable JSON shape before M2 storage is wired in.
  """

  @type op :: :add | :remove | :replace | :move | :copy | :test

  @type t :: %__MODULE__{
          op: op(),
          path: String.t(),
          value: term(),
          from: String.t() | nil,
          actor_id: String.t() | nil,
          timestamp: String.t() | nil,
          metadata: map()
        }

  @enforce_keys [:op, :path]
  defstruct [:op, :path, :value, :from, :actor_id, :timestamp, metadata: %{}]

  @valid_ops %{
    "add" => :add,
    "remove" => :remove,
    "replace" => :replace,
    "move" => :move,
    "copy" => :copy,
    "test" => :test
  }

  @spec from_map(map()) :: {:ok, t()} | {:error, term()}
  def from_map(attrs) when is_map(attrs) do
    with {:ok, op} <- normalize_op(value(attrs, :op)),
         {:ok, path} <- required_string(value(attrs, :path), :path) do
      {:ok,
       %__MODULE__{
         op: op,
         path: path,
         value: value(attrs, :value),
         from: value(attrs, :from),
         actor_id: value(attrs, :actor_id),
         timestamp: value(attrs, :timestamp),
         metadata: normalize_map(value(attrs, :metadata))
       }}
    end
  end

  def from_map(_attrs), do: {:error, {:invalid_patch_operation, :not_a_map}}

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = patch) do
    %{
      op: Atom.to_string(patch.op),
      path: patch.path,
      value: patch.value,
      from: patch.from,
      actor_id: patch.actor_id,
      timestamp: patch.timestamp,
      metadata: patch.metadata || %{}
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp normalize_op(op) when is_atom(op), do: normalize_op(Atom.to_string(op))

  defp normalize_op(op) when is_binary(op) do
    case Map.fetch(@valid_ops, op) do
      {:ok, normalized} -> {:ok, normalized}
      :error -> {:error, {:invalid_patch_operation, {:op, op}}}
    end
  end

  defp normalize_op(op), do: {:error, {:invalid_patch_operation, {:op, op}}}

  defp required_string(value, _field) when is_binary(value) and byte_size(value) > 0,
    do: {:ok, value}

  defp required_string(_value, field),
    do: {:error, {:invalid_patch_operation, {field, :required}}}

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(_value), do: %{}

  defp value(attrs, key) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end
end
