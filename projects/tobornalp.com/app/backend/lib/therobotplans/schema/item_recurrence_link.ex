defmodule Therobotplans.Schema.ItemRecurrenceLink do
  @moduledoc """
  Links an item occurrence to its recurrence rule and its series lineage
  (WS-A US-011). Kept as a side table (not columns on the shared `items`) so the
  personal-todo lane owns the recurrence wiring end-to-end.

  * `rule_id` — the `recurrence_rules` row driving the series.
  * `recurrence_parent_id` — the *seed* item's id, shared by every occurrence in
    the series. The seed's own link has `recurrence_parent_id = seed.id`. This
    gives O(1) series history / streak scans (US-012, US-014) without an
    occurrences table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "item_recurrence_links" do
    field :recurrence_parent_id, :binary_id

    belongs_to :item, Therobotplans.Schema.Item
    belongs_to :rule, Therobotplans.Schema.RecurrenceRule

    timestamps(type: :utc_datetime)
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:item_id, :rule_id, :recurrence_parent_id])
    |> validate_required([:item_id, :rule_id])
    |> foreign_key_constraint(:item_id)
    |> foreign_key_constraint(:rule_id)
    |> unique_constraint(:item_id, name: :item_recurrence_links_item_id_index)
  end
end
