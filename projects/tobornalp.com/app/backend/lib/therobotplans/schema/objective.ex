defmodule Therobotplans.Schema.Objective do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @levels ~w(company team individual personal)
  @statuses ~w(draft active at_risk off_track completed archived)

  schema "objectives" do
    field :organization_id, :binary_id
    field :project_id, :binary_id
    field :owner_id, :binary_id
    field :level, :string, default: "personal"
    field :title, :string
    field :description, :string
    field :status, :string, default: "active"
    field :period, :string

    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :key_results, Therobotplans.Schema.KeyResult, foreign_key: :objective_id
    has_many :checkins, Therobotplans.Schema.OkrCheckin, foreign_key: :objective_id

    timestamps(type: :utc_datetime)
  end

  def changeset(objective, attrs) do
    objective
    |> cast(attrs, [:organization_id, :project_id, :parent_id, :owner_id, :level, :title, :description, :status, :period])
    |> validate_required([:organization_id, :title])
    |> validate_inclusion(:level, @levels)
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:parent_id)
  end

  def levels, do: @levels
  def statuses, do: @statuses
end
