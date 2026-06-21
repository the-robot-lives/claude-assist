defmodule TheRobotRemembers.Schema.Memory.Compartment do
  @moduledoc "An access-control partition for memories owned by an agent."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "memory_compartments" do
    field :slug, :string
    field :owner_agent, :string
    field :classification, Ecto.Enum, values: [:open, :restricted, :sealed], default: :open
    field :settings, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(compartment, attrs) do
    compartment
    |> cast(attrs, ~w(slug owner_agent classification settings)a)
    |> validate_required([:slug, :owner_agent])
    |> unique_constraint([:owner_agent, :slug], name: :uq_compartment)
  end
end
