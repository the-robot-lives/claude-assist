defmodule Therobotplans.Domains.Items.Tools.ItemUnlinkEntity do
  use Noizu.MCP.Server.Tool,
    name: "Item.UnlinkEntity",
    description: "Remove a link between an item and a non-item entity.",
    hidden: true,
    category: "Items"

  input do
    field :item_id, :string, required: true, description: "Item UUID"
    field :entity_type, :string, required: true, description: "Entity type used when linking"
    field :entity_id, :string, required: true, description: "UUID of the linked entity"
    field :link_type, :string, description: "Link type to remove (default relates_to)"
  end

  alias Therobotplans.Domains.Items.Links
  alias Therobotplans.MCP.Args

  @impl true
  def call(args, _ctx) do
    item_id = Args.get(args, :item_id)
    entity_type = Args.get(args, :entity_type)
    entity_id = Args.get(args, :entity_id)
    opts = [link_type: Args.get(args, :link_type) || "relates_to"]

    case Links.unlink_entity(item_id, entity_type, entity_id, opts) do
      {:ok, _} -> {:ok, %{unlinked: true}}
      {:error, :not_found} -> {:error, "Link not found"}
    end
  end
end
