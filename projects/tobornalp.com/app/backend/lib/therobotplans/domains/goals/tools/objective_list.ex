defmodule Therobotplans.Domains.Goals.Tools.ObjectiveList do
  use Noizu.MCP.Server.Tool,
    name: "Objective.List",
    description: "List objectives for an organization, optionally filtered by owner/level/status.",
    hidden: true,
    category: "Goals",
    annotations: [read_only_hint: true]

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.{Args, Resolve}

  input do
    field :organization, :string, required: true, description: "Organization slug or UUID"
    field :owner_id, :string, description: "Filter to objectives owned by this user"
    field :level, :string, description: "Filter by level"
    field :status, :string, description: "Filter by status"
    field :project, :string, description: "Filter to a project"
  end

  @impl true
  def call(args, _ctx) do
    case Resolve.organization_id(Args.get(args, :organization)) do
      nil ->
        {:error, "Organization '#{Args.get(args, :organization)}' not found"}

      org_id ->
        project =
          if p = Args.get(args, :project), do: Resolve.project(p), else: nil

        opts =
          [owner_id: Args.get(args, :owner_id), level: Args.get(args, :level),
           status: Args.get(args, :status), project_id: project && project.id]
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)

        objs = Goals.list_objectives(org_id, opts)

        {:ok,
         %{
           objectives:
             Enum.map(objs, fn o ->
               %{id: o.id, title: o.title, level: o.level, status: o.status, period: o.period,
                 owner_id: o.owner_id, progress: Goals.objective_progress(o.id)}
             end)
         }}
    end
  end
end
