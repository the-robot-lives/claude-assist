defmodule Therobotplans.Domains.Goals.Tools.ObjectiveGet do
  use Noizu.MCP.Server.Tool,
    name: "Objective.Get",
    description: "Get an objective by UUID, with its key results, check-ins, and progress.",
    hidden: true,
    category: "Goals",
    annotations: [read_only_hint: true]

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.Args

  input do
    field :objective, :string, required: true, description: "Objective UUID"
  end

  @impl true
  def call(args, _ctx) do
    case Goals.get_objective(Args.get(args, :objective)) do
      nil ->
        {:error, "Objective not found"}

      o ->
        {:ok,
         %{
           id: o.id,
           title: o.title,
           description: o.description,
           level: o.level,
           status: o.status,
           period: o.period,
           owner_id: o.owner_id,
           parent_id: o.parent_id,
           progress: Goals.objective_progress(o.id),
           key_results:
             Enum.map(o.key_results || [], fn kr ->
               %{id: kr.id, title: kr.title, target: kr.target_value, current: kr.current_value,
                 auto_progress: kr.auto_progress, status: kr.status, due_on: kr.due_on}
             end),
           checkins:
             Enum.map(o.checkins || [], fn c ->
               %{id: c.id, body: c.body, period: c.period, inserted_at: c.inserted_at}
             end)
         }}
    end
  end
end
