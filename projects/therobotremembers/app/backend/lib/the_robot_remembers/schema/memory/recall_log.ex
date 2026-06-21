defmodule TheRobotRemembers.Schema.Memory.RecallLog do
  @moduledoc "Append-only log of recall requests (latency, paths, results) for observability/eval."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "recall_log" do
    field :requester_id, :string
    field :owner_agent, :string
    field :mode, :string
    field :query, :string
    field :total_candidates, :integer
    field :returned_count, :integer
    field :hot_index_hit, :boolean, default: false
    field :duration_ms, :integer
    field :result_memory_ids, {:array, Ecto.UUID}, default: []
    field :path_breakdown, :map, default: %{}
    field :occurred_at, :utc_datetime_usec
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, ~w(requester_id owner_agent mode query total_candidates returned_count
                      hot_index_hit duration_ms result_memory_ids path_breakdown occurred_at)a)
    |> validate_required([:requester_id, :owner_agent, :mode])
  end
end
