defmodule Therobotplans.Domains.Goals.Tools.ObjectiveUpdate do
  use Noizu.MCP.Server.Tool,
    name: "Objective.Update",
    description: "Update an objective's title, description, level, status, or period.",
    hidden: true,
    category: "Goals"

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.Args

  input do
    field :objective, :string, required: true, description: "Objective UUID"
    field :title, :string, description: "New title"
    field :description, :string, description: "New description"
    field :level, :string, description: "company | team | individual | personal"
    field :status, :string, description: "draft|active|at_risk|off_track|completed|archived"
    field :period, :string, description: "Period e.g. 2026-Q3"
  end

  @impl true
  def call(args, _ctx) do
    attrs = Args.take(args, [:title, :description, :level, :status, :period])

    case Goals.update_objective(Args.get(args, :objective), attrs) do
      {:ok, o} -> {:ok, %{id: o.id, title: o.title, status: o.status, level: o.level}}
      {:error, :not_found} -> {:error, "Objective not found"}
      {:error, cs} -> {:error, "Failed: #{inspect(cs.errors)}"}
    end
  end
end
