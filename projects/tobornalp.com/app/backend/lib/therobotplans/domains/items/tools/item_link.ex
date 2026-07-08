defmodule Therobotplans.Domains.Items.Tools.ItemLink do
  use Noizu.MCP.Server.Tool,
    name: "Item.Link",
    description: "Create a directional link between two items.",
    hidden: true,
    category: "Items"

  input do
    field :source_item_id, :string, required: true, description: "Source item UUID"
    field :target_item_id, :string, required: true, description: "Target item UUID"

    field :link_type, :string,
      required: true,
      description: "blocks, blocked_by, relates_to, duplicates, parent_of, child_of"
  end

  alias Therobotplans.Domains.Items

  @impl true
  def call(args, _ctx) do
    source = args[:source_item_id] || args["source_item_id"]
    target = args[:target_item_id] || args["target_item_id"]
    link_type = args[:link_type] || args["link_type"]

    case Items.link(source, target, link_type) do
      {:ok, link} ->
        {:ok, %{id: link.id, source: source, target: target, link_type: link_type}}

      {:error, changeset} ->
        {:error, "Failed: #{inspect(changeset.errors)}"}
    end
  end
end
