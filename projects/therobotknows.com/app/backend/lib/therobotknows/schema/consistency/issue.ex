defmodule Therobotknows.Schema.Consistency.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "consistency_issues" do
    field :severity, :string
    field :kind, :string
    field :title, :string
    field :detail, :string, default: ""
    field :entry_ids, {:array, Ecto.UUID}, default: []
    field :status, :string, default: "open"
    field :resolution, :map

    belongs_to :universe, Therobotknows.Schema.Universe.Universe

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [
      :universe_id,
      :severity,
      :kind,
      :title,
      :detail,
      :entry_ids,
      :status,
      :resolution
    ])
    |> validate_required([:universe_id, :severity, :kind, :title])
    |> validate_inclusion(:severity, ~w(error warning suggestion))
    |> validate_inclusion(:status, ~w(open resolved dismissed))
  end
end
