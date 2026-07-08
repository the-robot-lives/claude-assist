defmodule Therobotplans.Domains.Items.Tools.ItemWatch do
  use Noizu.MCP.Server.Tool,
    name: "Item.Watch",
    description: "Watch or unwatch an item for change notifications.",
    hidden: true,
    category: "Items"

  input do
    field :item_id, :string, required: true, description: "Item UUID"
    field :persona, :string, required: true, description: "Persona slug"
    field :action, :string, description: "\"watch\" (default) or \"unwatch\""
  end

  alias Therobotplans.Services.Watch

  @impl true
  def call(args, _ctx) do
    item_id = args[:item_id] || args["item_id"]
    persona = args[:persona] || args["persona"]
    action = args[:action] || args["action"] || "watch"

    case action do
      "unwatch" ->
        case Watch.unwatch("item", item_id, persona) do
          {:ok, _} -> {:ok, %{item_id: item_id, persona: persona, watching: false}}
          {:error, :not_found} -> {:error, "Not watching this item"}
        end

      _ ->
        Watch.watch("item", item_id, persona)
        watchers = Watch.watchers("item", item_id)
        {:ok, %{item_id: item_id, persona: persona, watching: true, watchers: watchers}}
    end
  end
end
