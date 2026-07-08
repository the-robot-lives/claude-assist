defmodule Therobotplans.Domains.Goals.Tools.KeyResultLinkItem do
  use Noizu.MCP.Server.Tool,
    name: "KeyResult.LinkItem",
    description: "Link an item to a key result (for auto-progress). The item's completion drives the KR's current_value. Use after creating an auto_progress KR.",
    hidden: true,
    category: "Goals"

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.Args

  input do
    field :key_result, :string, required: true, description: "Key result UUID"
    field :item, :string, required: true, description: "Item UUID or human key"
    field :weight, :number, description: "Relative weight (default 1.0)"
  end

  @impl true
  def call(args, _ctx) do
    kr_id = Args.get(args, :key_result)
    item_ref = Args.get(args, :item)

    # Resolve the item to a UUID (accept human key).
    item_id =
      case Ecto.UUID.cast(item_ref) do
        {:ok, _} -> item_ref
        :error -> nil
      end

    weight = Args.get(args, :weight) || 1.0

    cond do
      is_nil(item_id) ->
        {:error, "Item must be a UUID (human-key lookup not yet wired here)"}

      true ->
        case Goals.link_item(kr_id, item_id, to_weight(weight)) do
          {:ok, link} -> {:ok, %{id: link.id, key_result_id: kr_id, item_id: item_id, weight: link.weight}}
          {:error, cs} -> {:error, "Failed: #{inspect(cs.errors)}"}
        end
    end
  end

  defp to_weight(w) when is_integer(w), do: Decimal.new(to_string(w))
  defp to_weight(w) when is_float(w), do: Decimal.from_float(w)
  defp to_weight(%Decimal{} = w), do: w
end
