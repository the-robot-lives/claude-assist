defmodule TheRobotRemembers.Schema.Memory.Quarantine do
  @moduledoc "A memory the Guardian flagged at ingest, held for review."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "memory_quarantine" do
    field :memory_id, Ecto.UUID
    field :owner_agent, :string
    field :reason, :string
    field :payload, :map, default: %{}
    field :resolved, :boolean, default: false

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(q, attrs) do
    q
    |> cast(attrs, ~w(memory_id owner_agent reason payload resolved)a)
    |> validate_required([:owner_agent, :reason])
  end
end
