defmodule TheRobotRemembers.Schema.Memory.AgentState do
  @moduledoc """
  Per-agent emotional/hormonal harness state. In Phase 0 this is read from config defaults
  (Monitor stub); from Phase 2 the Monitor GenServer maintains and checkpoints it here.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:agent_id, :string, autogenerate: false}
  schema "memory_agent_state" do
    field :status, :string, default: "active"
    field :current_emotional, Pgvector.Ecto.Vector
    field :baseline_emotional, Pgvector.Ecto.Vector
    field :current_bucket, :string
    field :last_bucket_refresh, :utc_datetime_usec
    field :metrics, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(state, attrs) do
    state
    |> cast(attrs, ~w(agent_id status current_emotional baseline_emotional current_bucket
                      last_bucket_refresh metrics)a)
    |> validate_required([:agent_id])
  end
end
