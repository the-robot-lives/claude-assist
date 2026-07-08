defmodule Therobotplans.Schema.KrItemLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "kr_item_links" do
    field :key_result_id, :binary_id
    field :item_id, :binary_id
    field :weight, :decimal, default: Decimal.new("1.0")

    timestamps(type: :utc_datetime)
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:key_result_id, :item_id, :weight])
    |> validate_required([:key_result_id, :item_id])
    |> unique_constraint([:key_result_id, :item_id], name: :idx_kr_item_links_unique)
    |> foreign_key_constraint(:key_result_id)
    |> foreign_key_constraint(:item_id)
  end
end
