defmodule Mix.Tasks.Trr.Sim.Load do
  @shortdoc "Load simulated memory YAML fixtures into the memory engine (agent-bound)."
  @moduledoc """
  Reads the simulated corpus at `sim/memory/{agent}/{date}/memories.yaml` and archives each
  memory via `TheRobotRemembers.Memory.remember/2` (delegating to `Memory.SimLoader`), bound to
  the agent and carrying the fixture's explicit neurotransmitters/mood/timestamp/texts plus
  provenance in `environment`. After insert it drains the `:memory` Oban queue so embeddings (if
  configured) and the Weaver association graph are built before the task exits.

      mix trr.sim.load                              # agent "aria", dir ../../sim/memory
      mix trr.sim.load --agent aria --reset         # clear the agent's memories first
      mix trr.sim.load --dir /abs/sim/memory --agent aria
  """
  use Mix.Task
  import Ecto.Query

  alias TheRobotRemembers.Repo
  alias TheRobotRemembers.Schema.Memory.Memory, as: MemSchema
  alias TheRobotRemembers.Memory.SimLoader

  @requirements ["app.start"]
  @switches [agent: :string, dir: :string, reset: :boolean]

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, switches: @switches)
    agent = opts[:agent] || "aria"
    dir = opts[:dir] || SimLoader.default_dir()

    unless File.dir?(Path.join(dir, agent)), do: Mix.raise("sim dir not found: #{Path.join(dir, agent)}")

    if opts[:reset] do
      {n, _} = Repo.delete_all(from(m in MemSchema, where: m.owner_agent == ^agent))
      Mix.shell().info("reset: deleted #{n} existing memories for #{agent}")
    end

    r = SimLoader.load(agent, dir: dir)
    Mix.shell().info("loaded #{r.ok} memories from #{r.files} day-files for #{agent} (quarantined #{r.quarantined}, errors #{r.error})")
    drain()
    Mix.shell().info("done — embeddings/associations drained.")
  end

  defp drain do
    Oban.drain_queue(queue: :memory, with_recursion: true, with_safety: true)
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end
end
