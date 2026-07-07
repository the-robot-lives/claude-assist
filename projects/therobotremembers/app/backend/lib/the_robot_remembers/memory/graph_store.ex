defmodule TheRobotRemembers.Memory.GraphStore do
  @moduledoc """
  ADR-006 / ADR-013 seam: the association-graph operations that recall and the console run now live
  behind a **pluggable backend**, selected by config.

    * `:cte` (default) — the recursive-CTE implementations that have always backed these operations,
      extracted here verbatim. Semantics are byte-identical; selecting `:cte` must not change any
      result.
    * `:age` — the same operations against the Apache AGE projection (`trr_memory`) via `cypher()`.
      Requires `AGE_GRAPH_ENABLED` and a backfilled projection. AGE's variable-length expansion has
      **no per-node fan-out cap**, so `:age` results are a *superset* of `:cte` (see `GraphStore.AGE`).

  Four callbacks cover the two shapes each operation now has:

    * `rank_list/2`     — spreading-activation frontier expansion (recall's graph path).
    * `subgraph/2`      — the console's owner-scoped node+edge fetch.
    * `neighborhood/3`  — the seed traversal that narrows a subgraph to a neighborhood.
    * `explain_paths/3` — per-target best path (the Accords' "recalled because A→causal→B" surface).

  Adapter choice is validated at boot (`validate!/0`): selecting `:age` without the AGE layer enabled
  raises with a clear message rather than silently degrading.
  """

  alias TheRobotRemembers.Repo.AGE, as: AgeRepo

  @typedoc "A reachable memory and its best path score."
  @type score_row :: %{memory_id: String.t(), score: float()}

  @typedoc "An owner-scoped subgraph fetch: memory + edge structs, and whether the node cap truncated it."
  @type subgraph :: %{nodes: [struct()], edges: [struct()], truncated: boolean()}

  @typedoc "One hop of an explanation path: the edge type + weight traversed and the node reached."
  @type path_hop :: %{edge_type: atom() | String.t(), weight: float(), node_id: String.t()}

  @callback rank_list(seed_ids :: [String.t()], opts :: keyword()) ::
              {:ok, [score_row()]} | {:error, term()}

  @callback subgraph(owner_agent :: String.t(), opts :: keyword()) ::
              {:ok, subgraph()} | {:error, term()}

  @callback neighborhood(seed_id :: String.t(), hops :: pos_integer(), opts :: keyword()) ::
              {:ok, [String.t()]} | {:error, term()}

  @callback explain_paths(seed_ids :: [String.t()], target_ids :: [String.t()], opts :: keyword()) ::
              {:ok, %{optional(String.t()) => [path_hop()]}} | {:error, term()}

  @cte TheRobotRemembers.Memory.GraphStore.CTE
  @age TheRobotRemembers.Memory.GraphStore.AGE

  @doc "Runtime config (`adapter: :cte | :age`)."
  def config, do: Application.get_env(:the_robot_remembers, :graph_store, [])

  @doc "The active adapter module."
  def adapter do
    case config()[:adapter] do
      :age -> @age
      _ -> @cte
    end
  end

  @doc "The active adapter as an atom (`:cte | :age`) — recall's rank-list source tag."
  def adapter_name, do: if(adapter() == @age, do: :age, else: :cte)

  @doc """
  Boot-time guard: `:age` is only valid when the AGE graph layer is enabled. Called from the
  application supervisor so a misconfiguration fails fast with a clear message instead of taking
  recall down on the first query.
  """
  def validate! do
    if config()[:adapter] == :age and not AgeRepo.enabled?() do
      raise """
      graph_store adapter is :age but the AGE graph layer is disabled.
      Set AGE_GRAPH_ENABLED=true (and ensure the trr_memory projection is provisioned/backfilled),
      or unset GRAPH_STORE (defaults to :cte).
      """
    end

    :ok
  end

  @doc "Spreading-activation traversal from a seed frontier via the active adapter."
  def rank_list(seed_ids, opts \\ []), do: adapter().rank_list(seed_ids, opts)

  @doc "Owner-scoped subgraph fetch via the active adapter."
  def subgraph(owner_agent, opts \\ []), do: adapter().subgraph(owner_agent, opts)

  @doc "Reachable-id traversal from a seed via the active adapter."
  def neighborhood(seed_id, hops, opts \\ []), do: adapter().neighborhood(seed_id, hops, opts)

  @doc "Per-target best explanation path via the active adapter."
  def explain_paths(seed_ids, target_ids, opts \\ []),
    do: adapter().explain_paths(seed_ids, target_ids, opts)
end
