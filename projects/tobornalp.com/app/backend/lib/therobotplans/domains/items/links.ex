defmodule Therobotplans.Domains.Items.Links do
  @moduledoc """
  Cross-domain links between an item and any non-item entity (an OKR/key result,
  etc.), backed by the polymorphic `item_entity_links` table. There is no DB FK
  on `entity_id` (it spans domains), so callers should validate the target exists
  before linking (see `link_entity/4`).
  """
  import Ecto.Query, except: [update: 2]

  alias Therobotplans.Repo
  alias Therobotplans.Schema.{ItemEntityLink, Item}

  @doc """
  Link `item_id` to an entity. Validates the item exists (entity targets are
  validated by the calling tool, which knows the entity's table). `link_type`
  defaults to "relates_to".
  """
  def link_entity(item_id, entity_type, entity_id, opts \\ []) do
    link_type = opts[:link_type] || "relates_to"
    metadata = opts[:metadata] || %{}

    cond do
      is_nil(Repo.get(Item, item_id)) ->
        {:error, :item_not_found}

      true ->
        %ItemEntityLink{}
        |> ItemEntityLink.changeset(%{
          item_id: item_id,
          entity_type: to_string(entity_type),
          entity_id: entity_id,
          link_type: link_type,
          metadata: metadata
        })
        |> Repo.insert()
    end
  end

  def unlink_entity(item_id, entity_type, entity_id, opts \\ []) do
    link_type = opts[:link_type] || "relates_to"

    case Repo.get_by(ItemEntityLink,
           item_id: item_id,
           entity_type: to_string(entity_type),
           entity_id: entity_id,
           link_type: link_type) do
      nil -> {:error, :not_found}
      link -> Repo.delete(link)
    end
  end

  @doc "All entity links for an item (forward direction)."
  def get_entity_links(item_id) do
    ItemEntityLink
    |> where([l], l.item_id == ^item_id)
    |> order_by([l], asc: l.entity_type, asc: l.inserted_at)
    |> Repo.all()
  end

  @doc "All items linked to a given entity (reverse lookup)."
  def get_items_for(entity_type, entity_id) do
    ItemEntityLink
    |> where([l], l.entity_type == ^to_string(entity_type) and l.entity_id == ^entity_id)
    |> order_by([l], asc: l.inserted_at)
    |> Repo.all()
  end
end
