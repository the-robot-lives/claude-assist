defmodule TheRobotRemembers.Memory.SimLoader do
  @moduledoc """
  Loads the simulated memory corpus (`sim/memory/{agent}/{date}/memories.yaml`) into the memory
  engine via `Memory.remember/2`, bound to the agent, carrying the fixture's explicit
  neurotransmitters/mood/timestamp/texts + provenance in `environment`. Shared by the
  `mix trr.sim.load` task and the recall test suite.
  """
  alias TheRobotRemembers.Memory

  @doc "Default corpus dir: backend cwd is app/backend → ../../sim/memory."
  def default_dir, do: Path.expand(Path.join([File.cwd!(), "..", "..", "sim", "memory"]))

  @doc "Day-file paths for an agent, sorted by date."
  def files(agent, dir \\ default_dir()) do
    dir |> Path.join(agent) |> Path.join("*/memories.yaml") |> Path.wildcard() |> Enum.sort()
  end

  @doc "Load all of an agent's day-files. Returns counts `%{files, ok, quarantined, error}`."
  def load(agent, opts \\ []) do
    dir = opts[:dir] || default_dir()
    ctx = %{owner_agent: agent, source_agent: "sim", requester_id: agent}

    Enum.reduce(files(agent, dir), %{files: 0, ok: 0, quarantined: 0, error: 0}, fn file, acc ->
      day = YamlElixir.read_from_file!(file)
      acc = %{acc | files: acc.files + 1}

      Enum.reduce(day["memories"] || [], acc, fn m, a ->
        case Memory.remember(to_attrs(m, day), ctx) do
          {:ok, %{status: :quarantined}} -> %{a | quarantined: a.quarantined + 1}
          {:ok, _} -> %{a | ok: a.ok + 1}
          {:error, _} -> %{a | error: a.error + 1}
        end
      end)
    end)
  end

  @doc "Map a fixture memory + its day envelope to `Memory.remember/2` attrs."
  def to_attrs(m, day) do
    %{
      content: m["content"],
      context: m["context"],
      reflection: m["reflection"],
      tangent: m["tangent"],
      summary: m["summary"],
      content_type: m["content_type"] || "episodic",
      domain: m["domain"],
      topic: m["topic"],
      collaborators: m["collaborators"] || [],
      mood: m["mood"],
      hormones: m["neurotransmitters"],
      occurred_at: m["occurred_at"],
      environment: %{
        "seq" => m["seq"],
        "salience" => m["salience"],
        "learned" => m["learned"],
        "project" => m["project"],
        "date" => day["date"],
        "day_index" => day["day_index"],
        "phase" => day["phase"]
      }
    }
  end
end
