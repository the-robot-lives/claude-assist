defmodule Mix.Tasks.Trr.Bench.Graph do
  @shortdoc "Benchmark recall traversal: recursive CTE vs Apache AGE (ADR-013 Phase C)"

  @moduledoc """
  Seed a synthetic association graph, then time the recall traversal on both backends — the
  recursive-CTE spreading activation (the live hot path) and the Apache AGE variable-length
  equivalent — reporting p50/p95/p99 latency per backend.

  Requires a database with Apache AGE installed and the `trr_memory` graph provisioned
  (Liquibase 031). The task issues `LOAD 'age'` on its own connection, so `AGE_GRAPH_ENABLED`
  need not be set for the benchmark itself.

      mix trr.bench.graph --nodes 100000 --edges 500000 --queries 50 --seed-size 40

  ## Options
    * `--nodes` / `-n`      number of synthetic memories (default 100_000)
    * `--edges` / `-e`      number of synthetic association edges (default 500_000)
    * `--queries` / `-q`    timed frontiers per backend (default 50)
    * `--seed-size` / `-s`  ids per frontier, simulating a Weaviate seed set (default 40)
    * `--batch`            insert / projection batch size (default 2_000)
    * `--scale-sweep`      ignore `--edges`; sweep 10k / 100k / 1M edges (per ADR-013), each with
                           `nodes = edges / 5`
    * `--keep`             leave the bench data in place (skip cleanup) for follow-up inspection

  All synthetic rows use `owner_agent = "bench"`; without `--keep` they are removed at the end.
  """
  use Mix.Task

  alias TheRobotRemembers.Bench.GraphBench

  @switches [
    nodes: :integer,
    edges: :integer,
    queries: :integer,
    seed_size: :integer,
    batch: :integer,
    keep: :boolean,
    scale_sweep: :boolean
  ]
  @aliases [n: :nodes, e: :edges, q: :queries, s: :seed_size]

  @sweep_edges [10_000, 100_000, 1_000_000]

  @impl Mix.Task
  def run(argv) do
    {opts, _rest, _invalid} = OptionParser.parse(argv, switches: @switches, aliases: @aliases)
    Mix.Task.run("app.start")

    queries = Keyword.get(opts, :queries, 50)
    seed_size = Keyword.get(opts, :seed_size, 40)
    batch = Keyword.get(opts, :batch, 2_000)
    keep? = Keyword.get(opts, :keep, false)

    if Keyword.get(opts, :scale_sweep, false) do
      Enum.each(@sweep_edges, fn edges ->
        run_one(max(1_000, div(edges, 5)), edges, queries, seed_size, batch, keep?)
      end)
    else
      nodes = Keyword.get(opts, :nodes, 100_000)
      edges = Keyword.get(opts, :edges, 500_000)
      run_one(nodes, edges, queries, seed_size, batch, keep?)
    end
  end

  defp run_one(nodes, edges, queries, seed_size, batch, keep?) do
    Mix.shell().info("[trr.bench.graph] seeding #{nodes} nodes / #{edges} edges (batch #{batch}) ...")
    %{ids: ids} = GraphBench.seed(nodes: nodes, edges: edges, batch: batch)

    Mix.shell().info("[trr.bench.graph] timing #{queries} queries (seed_size #{seed_size}) ...")
    GraphBench.run(ids: ids, queries: queries, seed_size: seed_size)

    if keep? do
      Mix.shell().info("[trr.bench.graph] --keep set; leaving bench data (owner_agent=\"bench\").")
    else
      {:ok, deleted} = GraphBench.cleanup()
      Mix.shell().info("[trr.bench.graph] cleaned up #{deleted} bench memories.")
    end
  end
end
