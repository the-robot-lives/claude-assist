defmodule Therobotplans.Schema.Objective do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @levels ~w(company team individual personal)
  @statuses ~w(draft active at_risk off_track completed archived)
  @rollup_strategies ~w(weighted_avg min_children custom)

  schema "objectives" do
    field :organization_id, :binary_id
    field :project_id, :binary_id
    field :owner_id, :binary_id
    field :level, :string, default: "personal"
    field :title, :string
    field :description, :string
    field :status, :string, default: "active"
    field :period, :string

    # ── US-069 hierarchy / rollup ──────────────────────────────
    # How this objective combines its child objectives + own KRs.
    field :rollup_strategy, :string, default: "weighted_avg"
    # This objective's contribution to its parent's weighted rollup.
    field :weight, :decimal, default: Decimal.new("1.0")
    # Sibling ordering for drag-reorder.
    field :sort_order, :integer, default: 0
    # Memoized rolled-up progress (0..1), written bottom-up by the domain.
    field :cached_progress, :decimal
    field :cached_progress_at, :utc_datetime

    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :key_results, Therobotplans.Schema.KeyResult, foreign_key: :objective_id
    has_many :checkins, Therobotplans.Schema.OkrCheckin, foreign_key: :objective_id

    timestamps(type: :utc_datetime)
  end

  def changeset(objective, attrs) do
    objective
    |> cast(attrs, [
      :organization_id,
      :project_id,
      :parent_id,
      :owner_id,
      :level,
      :title,
      :description,
      :status,
      :period,
      :rollup_strategy,
      :weight,
      :sort_order
    ])
    |> validate_required([:organization_id, :title])
    |> validate_inclusion(:level, @levels)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:rollup_strategy, @rollup_strategies)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:parent_id)
  end

  # Internal changeset for domain-managed cache writes (bypasses user-cast fields).
  def cache_changeset(objective, cached_progress, at) do
    change(objective, cached_progress: cached_progress, cached_progress_at: at)
  end

  def levels, do: @levels
  def statuses, do: @statuses
  def rollup_strategies, do: @rollup_strategies
end
