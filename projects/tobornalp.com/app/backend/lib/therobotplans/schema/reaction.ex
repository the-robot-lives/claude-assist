defmodule Therobotplans.Schema.Reaction do
  @moduledoc """
  Generic per-entity reaction keyed by (entity_type, entity_id). `persona` is the
  reactor (a user id). The backing table trp_reactions was created in changelog
  027 alongside trp_comments / trp_attachments / trp_watches — this schema (and
  Services.Reaction) completes the polymorphic quartet that 027 set up.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "trp_reactions" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :persona, :string
    field :emoji, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:entity_type, :entity_id, :persona, :emoji])
    |> validate_required([:entity_type, :entity_id, :persona, :emoji])
    |> unique_constraint([:entity_type, :entity_id, :persona, :emoji],
      name: :idx_trp_reactions_unique
    )
  end
end
