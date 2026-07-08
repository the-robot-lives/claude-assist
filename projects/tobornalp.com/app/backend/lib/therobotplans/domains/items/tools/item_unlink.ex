defmodule Therobotplans.Domains.Items.Tools.ItemUnlink do
  use Noizu.MCP.Server.Tool,
    name: "Item.Unlink",
    description: "Remove a link between two items.",
    hidden: true,
    category: "Items"

  input do
    field :source_item_id, :string, required: true, description: "Source item UUID"
    field :target_item_id, :string, required: true, description: "Target item UUID"
    field :link_type, :string, required: true, description: "Link type to remove"
  end

  alias Therobotplans.Domains.Items

  @impl true
  def call(args, _ctx) do
    source = args[:source_item_id] || args["source_item_id"]
    target = args[:target_item_id] || args["target_item_id"]
    link_type = args[:link_type] || args["link_type"]

    case Items.unlink(source, target, link_type) do
      {:ok, _} -> {:ok, %{unlinked: true}}
      {:error, :not_found} -> {:error, "Link not found"}
    end
  end
end
