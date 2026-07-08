defmodule Therobotplans.Domains.Items.Tools.ItemLinkEntity do
  use Noizu.MCP.Server.Tool,
    name: "Item.LinkEntity",
    description: "Link an item to a non-item entity (customer_persona, customer_segment, campaign, keyword, competitor, market_report, landing_page, domain_name, ad_group, ad_copy).",
    hidden: true,
    category: "Items"

  input_schema %{
    "type" => "object",
    "properties" => %{
      "item_id" => %{"type" => "string", "description" => "Item UUID"},
      "entity_type" => %{"type" => "string", "description" => "Entity type: customer_persona, customer_segment, campaign, keyword, competitor, market_report, landing_page, domain_name, ad_group, ad_copy"},
      "entity_id" => %{"type" => "string", "description" => "UUID of the linked entity"},
      "link_type" => %{"type" => "string", "description" => "relates_to (default), targets, derived_from, addresses, blocks, references"},
      "metadata" => %{"type" => "object", "description" => "Optional metadata for the link"}
    },
    "required" => ["item_id", "entity_type", "entity_id"]
  }

  alias Therobotplans.Domains.Items.Links
  alias Therobotplans.MCP.Args

  @impl true
  def call(args, _ctx) do
    item_id = Args.get(args, :item_id)
    entity_type = Args.get(args, :entity_type)
    entity_id = Args.get(args, :entity_id)
    opts = [link_type: Args.get(args, :link_type) || "relates_to", metadata: Args.get(args, :metadata) || %{}]

    case Links.link_entity(item_id, entity_type, entity_id, opts) do
      {:ok, link} ->
        {:ok, %{id: link.id, item_id: item_id, entity_type: link.entity_type, entity_id: entity_id, link_type: link.link_type}}
      {:error, :item_not_found} ->
        {:error, "Item '#{item_id}' not found"}
      {:error, changeset} ->
        {:error, "Failed: #{inspect(changeset.errors)}"}
    end
  end
end
