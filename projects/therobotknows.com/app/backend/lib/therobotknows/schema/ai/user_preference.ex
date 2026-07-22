defmodule Therobotknows.Schema.AI.UserPreference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.UUID

  schema "user_ai_preferences" do
    field :user_id, Ecto.UUID, primary_key: true
    field :model, :string, default: "default"
    field :monthly_budget_cents, :integer, default: 1000
    field :settings, :map, default: %{}
    field :updated_at, :utc_datetime_usec
  end

  def changeset(pref, attrs) do
    pref
    |> cast(attrs, [:user_id, :model, :monthly_budget_cents, :settings, :updated_at])
    |> validate_required([:user_id, :model, :monthly_budget_cents])
    |> validate_number(:monthly_budget_cents, greater_than_or_equal_to: 0)
  end
end
