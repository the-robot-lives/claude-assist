defmodule Therobotplans.Schema.OkrCheckin do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "okr_checkins" do
    field :author_id, :binary_id
    field :body, :string
    field :period, :string

    belongs_to :objective, Therobotplans.Schema.Objective

    timestamps(type: :utc_datetime)
  end

  def changeset(checkin, attrs) do
    checkin
    |> cast(attrs, [:objective_id, :author_id, :body, :period])
    |> validate_required([:objective_id, :body])
    |> foreign_key_constraint(:objective_id)
  end
end
