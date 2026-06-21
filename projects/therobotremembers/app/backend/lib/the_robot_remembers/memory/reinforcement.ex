defmodule TheRobotRemembers.Memory.Reinforcement do
  @moduledoc """
  Weight dynamics (ADR-005). On recall, the *decision* of what to reinforce is computed inline
  (the returned set), and the durable *write* is an Oban job (`ReinforcementWorker`) so recall
  returns immediately. Explicit `reinforce`/`denforce` are applied synchronously. All weights
  clamp to [0.05, 1.0].
  """
  import Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.Memory
  alias TheRobotRemembers.Workers.ReinforcementWorker

  def config, do: Application.get_env(:the_robot_remembers, :reinforcement, [])
  defp explicit_boost, do: config()[:explicit_boost] || 0.1
  defp denforce_penalty, do: config()[:denforce_penalty] || 0.05

  @doc "Async, durable light reinforcement of a recall result set (memories + edges + Hebbian)."
  def on_recall([], _context), do: :ok

  def on_recall(rows, context) do
    ids = rows |> Enum.map(& &1.id) |> Enum.filter(&is_binary/1) |> Enum.uniq()

    if ids == [] do
      :ok
    else
      %{"memory_ids" => ids, "owner" => context[:owner_agent]}
      |> ReinforcementWorker.new()
      |> Oban.insert()

      :ok
    end
  rescue
    _ -> :ok
  catch
    :exit, _ -> :ok
  end

  @doc "Explicit, synchronous reinforce of one memory. Returns {:ok, new_decay_weight}."
  def reinforce(memory_id, context \\ %{}), do: adjust(memory_id, context, explicit_boost(), :up)

  @doc "Explicit, synchronous denforce of one memory. Returns {:ok, new_decay_weight}."
  def denforce(memory_id, context \\ %{}), do: adjust(memory_id, context, denforce_penalty(), :down)

  defp adjust(memory_id, context, delta, dir) do
    owner = context[:owner_agent]

    {wexpr, ccol} =
      case dir do
        :up -> {"LEAST(1.0, decay_weight + $2)", "reinforcement_count"}
        :down -> {"GREATEST(0.05, decay_weight - $2)", "denforcement_count"}
      end

    {owner_clause, params} =
      if owner, do: {" AND owner_agent = $3", [memory_id, delta, owner]}, else: {"", [memory_id, delta]}

    last =
      if dir == :up, do: ", last_reinforced_at = now()", else: ""

    sql =
      "UPDATE memories SET decay_weight = #{wexpr}, #{ccol} = #{ccol} + 1#{last}, updated_at = now() " <>
        "WHERE id = $1::text::uuid#{owner_clause} RETURNING decay_weight"

    case Ecto.Adapters.SQL.query(Repo, sql, params) do
      {:ok, %{rows: [[w]]}} -> {:ok, w}
      {:ok, %{rows: []}} -> {:error, :not_found}
      {:error, e} -> {:error, e}
    end
  end

  @doc "Existing edges of a memory (for the `memory_associations` tool)."
  def associations(memory_id, context \\ %{}) do
    owner = context[:owner_agent]

    edges =
      from(e in TheRobotRemembers.Schema.Memory.AssociationEdge,
        where: e.source_memory_id == ^memory_id or e.target_memory_id == ^memory_id,
        order_by: [desc: e.weight]
      )
      |> Repo.all()

    # ownership is enforced by the memory's owner; filter defensively if owner known
    if owner do
      mine = Repo.exists?(from m in Memory, where: m.id == ^memory_id and m.owner_agent == ^owner)
      if mine, do: edges, else: []
    else
      edges
    end
  end
end
