defmodule TheRobotRemembers.Repo.AGE do
  @moduledoc """
  Per-connection Apache AGE session setup for `TheRobotRemembers.Repo`.

  AGE needs two session-local settings before any `cypher(...)` call:

    * `LOAD 'age';` — loads the extension library into the connection.
    * ag_catalog on the `search_path` — so `cypher`, `agtype`, and the graph functions resolve.

  Postgrex does **not** accept multi-statement queries, so this runs as two separate
  `Postgrex.query!/3` calls wired in as the Repo's `after_connect` MFA (see `config/config.exs`).
  Postgrex invokes it as `after_connect(conn)` on every new connection.

  `ag_catalog` is placed **last** in the search_path (`"$user", public, ag_catalog`) so AGE's
  catalog never shadows the app's own schema objects during ordinary queries — `cypher`/`agtype`
  live only in ag_catalog, so a fallback position is enough for them to resolve.

  Gated by `AGE_GRAPH_ENABLED` → `config :the_robot_remembers, :age_graph, enabled: …`, mirroring
  the Weaviate flag. When disabled the hook **no-ops**, so the app boots and runs normally against
  a database that does not have AGE installed (dev, test, any DB where the graph layer is off).
  """

  @doc "Runtime config for the AGE graph layer (`enabled`, `graph`, `min_edge_weight`)."
  def config, do: Application.get_env(:the_robot_remembers, :age_graph, [])

  @doc "Whether the AGE graph projection is turned on for this node."
  def enabled?, do: config()[:enabled] == true

  @doc "Name of the AGE graph (schema) backing the projection."
  def graph_name, do: config()[:graph] || "trr_memory"

  @doc """
  Postgrex `after_connect` hook. Prepares the connection for AGE when the graph layer is enabled;
  a no-op otherwise. Uses the bang variant so a misconfiguration (AGE_GRAPH_ENABLED=true against a
  database without AGE) fails the connection loudly rather than silently degrading.
  """
  def after_connect(conn) do
    if enabled?() do
      Postgrex.query!(conn, "LOAD 'age'", [])
      Postgrex.query!(conn, ~s(SET search_path = "$user", public, ag_catalog), [])
    end

    :ok
  end
end
