defmodule Therobotplans.Domains.Items.Tools.ItemFeed do
  use Noizu.MCP.Server.Tool,
    name: "Item.Feed",
    description: "Activity feed for an item.",
    hidden: true,
    category: "Items",
    annotations: [read_only_hint: true]

  input do
    field :item_id, :string, required: true, description: "Item UUID"
    field :limit, :integer, description: "Max events (default 50)"
  end

  @impl true
  def call(args, _ctx) do
    item_id = args[:item_id] || args["item_id"]

    {:ok,
     %{
       item_id: item_id,
       events: [],
       hint: "Activity feed not yet implemented."
     }}
  end
end
