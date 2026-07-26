defmodule HoloGraph.Docs.PatchBatch do
  @moduledoc """
  The patch-batch wire protocol for HoloGraph documents.

  Semantic editor ops (`add_node`/`connect`/`rename`/`reparent`/`delete`) are the
  protocol — they match the editor's undo history 1:1 (see the frontend
  `PatchOperation` type). A batch is stored verbatim in `collab_events.patch`
  and de-duplicated on `client_event_id`; JSON-Patch translation is deliberately
  not performed.

  A batch may carry the post-batch `document` payload. When present the server
  persists it as the new document state (after envelope validation and
  sanitization); when absent only the event log and version counter advance and
  the stored document is left untouched.
  """

  alias HoloGraph.Docs.Document

  @operation_types ~w(add_node connect rename reparent delete)
  @default_event_type "patch_batch"

  @type t :: %__MODULE__{
          client_event_id: String.t() | nil,
          event_type: String.t(),
          base_version: pos_integer() | nil,
          operations: [map()],
          document: map() | nil,
          metadata: map()
        }

  defstruct client_event_id: nil,
            event_type: @default_event_type,
            base_version: nil,
            operations: [],
            document: nil,
            metadata: %{}

  @spec operation_types() :: [String.t()]
  def operation_types, do: @operation_types

  @doc """
  Normalizes and validates an inbound patch batch.

  Accepts snake_case and camelCase envelope keys (`client_event_id` /
  `clientEventId` / `patchId`, `base_version` / `baseVersion`).
  """
  @spec parse(term()) :: {:ok, t()} | {:error, {:invalid_patch_batch, [String.t()]}}
  def parse(input) when is_map(input) do
    batch = Document.stringify(input)
    operations = fetch(batch, ["operations", "patches", "ops"])

    errors =
      []
      |> validate_operations(operations)
      |> validate_client_event_id(fetch(batch, ["client_event_id", "clientEventId", "patchId"]))
      |> validate_base_version(fetch(batch, ["base_version", "baseVersion"]))
      |> Enum.reverse()

    with [] <- errors,
         {:ok, document} <- parse_document(fetch(batch, ["document"])) do
      {:ok,
       %__MODULE__{
         client_event_id: fetch(batch, ["client_event_id", "clientEventId", "patchId"]),
         event_type: fetch(batch, ["event_type", "eventType"]) || @default_event_type,
         base_version: fetch(batch, ["base_version", "baseVersion"]),
         operations: operations || [],
         document: document,
         metadata: fetch(batch, ["metadata"]) || %{}
       }}
    else
      [_ | _] = errors -> {:error, {:invalid_patch_batch, errors}}
      {:error, {:invalid_document, reasons}} -> {:error, {:invalid_patch_batch, reasons}}
    end
  end

  def parse(_input), do: {:error, {:invalid_patch_batch, ["patch batch must be an object"]}}

  @doc """
  The verbatim jsonb payload persisted to `collab_events.patch`.
  """
  @spec to_patch_payload(t()) :: map()
  def to_patch_payload(%__MODULE__{} = batch) do
    %{
      "client_event_id" => batch.client_event_id,
      "event_type" => batch.event_type,
      "base_version" => batch.base_version,
      "operations" => batch.operations
    }
  end

  defp parse_document(nil), do: {:ok, nil}

  defp parse_document(document) do
    case Document.validate_and_normalize(document) do
      {:ok, normalized} -> {:ok, normalized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_operations(errors, operations) when is_list(operations) do
    Enum.reduce(operations, errors, fn
      operation, acc when is_map(operation) ->
        case Map.get(operation, "type") do
          type when type in @operation_types -> acc
          type -> ["unsupported operation type: #{inspect(type)}" | acc]
        end

      _operation, acc ->
        ["each operation must be an object" | acc]
    end)
  end

  defp validate_operations(errors, nil), do: ["operations must be an array" | errors]
  defp validate_operations(errors, _operations), do: ["operations must be an array" | errors]

  defp validate_client_event_id(errors, nil), do: errors

  defp validate_client_event_id(errors, id) when is_binary(id) do
    if String.length(id) <= 128 and id != "" do
      errors
    else
      ["client_event_id must be a non-empty string of at most 128 characters" | errors]
    end
  end

  defp validate_client_event_id(errors, _id),
    do: ["client_event_id must be a string" | errors]

  defp validate_base_version(errors, nil), do: errors

  defp validate_base_version(errors, version) when is_integer(version) and version > 0, do: errors

  defp validate_base_version(errors, _version),
    do: ["base_version must be a positive integer" | errors]

  defp fetch(map, keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(map, key) do
        nil -> nil
        value -> value
      end
    end)
  end
end
