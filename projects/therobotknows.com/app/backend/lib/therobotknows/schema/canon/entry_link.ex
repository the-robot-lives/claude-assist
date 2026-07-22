defmodule Therobotknows.Schema.Canon.EntryLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "entry_links" do
    field :relationship, :string
    field :excerpt, :string
    field :created_by, Ecto.UUID

    belongs_to :universe, Therobotknows.Schema.Universe.Universe
    belongs_to :source_entry, Therobotknows.Schema.Canon.Entry
    belongs_to :target_entry, Therobotknows.Schema.Canon.Entry

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [
      :universe_id,
      :source_entry_id,
      :target_entry_id,
      :relationship,
      :excerpt,
      :created_by
    ])
    |> validate_required([
      :universe_id,
      :source_entry_id,
      :target_entry_id,
      :relationship
    ])
    |> validate_length(:relationship, min: 1, max: 255)
    |> unique_constraint([:source_entry_id, :target_entry_id, :relationship],
      name: :uq_entry_links_triple
    )
  end
end
