defmodule Therobotplans.Schema.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Generic per-entity comment keyed by (entity_type, entity_id). Items use
  # entity_type = "item". Ported from NPL Schema.Comment (npl_comments → trp_comments).
  schema "trp_comments" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :content, :string
    field :author, :string
    field :location, :string
    field :reply_to_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:entity_type, :entity_id, :content, :author, :location, :reply_to_id])
    |> validate_required([:entity_type, :entity_id, :content])
  end
end
