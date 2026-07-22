defmodule Therobotknows.Schema.Generation.Generation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "generations" do
    field :prompt, :string
    field :entry_type, :string
    field :status, :string, default: "pending"
    field :params, :map, default: %{}
    field :output_title, :string
    field :output_body, :map
    field :output_entry_id, Ecto.UUID
    field :source_entry_ids, {:array, Ecto.UUID}, default: []
    field :citations, Therobotknows.Schema.Canon.JsonStringList, default: []
    field :error_message, :string
    field :token_usage, :map, default: %{}
    field :cost_cents, :integer
    field :created_by, Ecto.UUID

    belongs_to :universe, Therobotknows.Schema.Universe.Universe

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(gen, attrs) do
    gen
    |> cast(attrs, [
      :universe_id,
      :prompt,
      :entry_type,
      :status,
      :params,
      :output_title,
      :output_body,
      :output_entry_id,
      :source_entry_ids,
      :citations,
      :error_message,
      :token_usage,
      :cost_cents,
      :created_by
    ])
    |> validate_required([:universe_id, :prompt, :entry_type, :status])
    |> validate_inclusion(:entry_type, Therobotknows.Schema.Canon.Entry.entry_types())
    |> validate_inclusion(:status, ~w(pending running complete failed promoted discarded))
  end
end
