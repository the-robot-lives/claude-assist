defmodule Therobotplans.Schema.KeyResult do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @directions ~w(higher_better lower_better)
  @statuses ~w(on_track at_risk behind completed)

  schema "key_results" do
    field :owner_id, :binary_id
    field :title, :string
    field :unit, :string
    field :target_value, :decimal, default: Decimal.new("100")
    field :current_value, :decimal, default: Decimal.new("0")
    field :direction, :string, default: "higher_better"
    field :due_on, :date
    field :status, :string, default: "on_track"
    # When true, current_value is auto-computed from linked item completion.
    field :auto_progress, :boolean, default: false

    belongs_to :objective, Therobotplans.Schema.Objective
    has_many :item_links, Therobotplans.Schema.KrItemLink, foreign_key: :key_result_id

    timestamps(type: :utc_datetime)
  end

  def changeset(kr, attrs) do
    kr
    |> cast(attrs, [:objective_id, :owner_id, :title, :unit, :target_value, :current_value, :direction, :due_on, :status, :auto_progress])
    |> validate_required([:objective_id, :title])
    |> validate_inclusion(:direction, @directions)
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:objective_id)
  end

  # For auto-progress KRs current_value is managed by the domain, not user input.
  def manual_changeset(kr, attrs) do
    kr
    |> changeset(attrs)
    |> then(fn cs ->
      if get_field(cs, :auto_progress), do: delete_change(cs, :current_value), else: cs
    end)
  end

  def directions, do: @directions
  def statuses, do: @statuses
end
