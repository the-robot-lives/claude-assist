defmodule Therobotplans.Domains.Items.Tools.ItemGet do
  use Noizu.MCP.Server.Tool,
    name: "Item.Get",
    description: "Fetch an item by UUID with fields, links, and attachments.",
    hidden: true,
    category: "Items",
    annotations: [read_only_hint: true]

  input do
    field :item_id, :string, required: true, description: "Item UUID"
  end

  alias Therobotplans.Domains.Items
  alias Therobotplans.Domains.Items.Definitions

  @impl true
  def call(args, _ctx) do
    item_id = args[:item_id] || args["item_id"]

    case Items.get(item_id) do
      nil ->
        {:error, "Item '#{item_id}' not found"}

      item ->
        links = Items.get_links(item_id)

        type_fields =
          case Definitions.resolve_type(item.organization_id, item.project_id, item.item_type) do
            nil -> []
            type_def -> Definitions.type_field_list(type_def)
          end

        {:ok, %{
          id: item.id,
          title: item.title,
          description: item.description,
          item_type: item.item_type,
          status: item.status,
          priority: item.priority,
          assignee: item.assignee,
          reporter: item.reporter,
          project_id: item.project_id,
          queue_id: item.queue_id,
          parent_id: item.parent_id,
          custom_fields: item.custom_fields,
          type_fields: type_fields,
          links: %{
            outgoing: Enum.map(links.outgoing, fn l ->
              %{item_id: l.target_item_id, link_type: l.link_type}
            end),
            incoming: Enum.map(links.incoming, fn l ->
              %{item_id: l.source_item_id, link_type: l.link_type}
            end)
          },
          created_at: item.inserted_at,
          updated_at: item.updated_at
        }}
    end
  end
end
