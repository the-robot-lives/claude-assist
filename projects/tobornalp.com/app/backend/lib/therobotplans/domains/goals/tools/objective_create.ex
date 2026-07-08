defmodule Therobotplans.Domains.Goals.Tools.ObjectiveCreate do
  use Noizu.MCP.Server.Tool,
    name: "Objective.Create",
    description: "Create an objective (OKR). Level: company|team|individual|personal.",
    hidden: true,
    category: "Goals"

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.{Args, Resolve}

  input do
    field :organization, :string, required: true, description: "Organization slug or UUID"
    field :project, :string, description: "Optional project slug or UUID"
    field :title, :string, required: true, description: "Objective title"

    field :level, :string,
      description: "company | team | individual | personal (default personal)"

    field :owner_id, :string, description: "Owner user UUID (defaults to the caller)"
    field :parent_id, :string, description: "Parent objective UUID (for cascade)"
    field :period, :string, description: "Period e.g. 2026-Q3"
    field :description, :string, description: "Objective description"
  end

  @impl true
  def call(args, ctx) do
    org_ref = Args.get(args, :organization)
    project_ref = Args.get(args, :project)

    with {:scope, {:ok, org_id, project_id}} <- {:scope, Resolve.scope(org_ref, project_ref)},
         {:ok, owner_id} <- owner(args, ctx) do
      attrs =
        %{
          organization_id: org_id,
          project_id: project_id,
          owner_id: owner_id,
          parent_id: Args.get(args, :parent_id),
          title: Args.get(args, :title),
          description: Args.get(args, :description),
          level: Args.get(args, :level) || "personal",
          period: Args.get(args, :period)
        }

      case Goals.create_objective(attrs) do
        {:ok, o} -> {:ok, %{id: o.id, title: o.title, level: o.level, status: o.status}}
        {:error, cs} -> {:error, "Failed: #{inspect(cs.errors)}"}
      end
    else
      {:scope, {:error, :org_not_found}} ->
        {:error, "Organization '#{org_ref}' not found"}

      {:scope, err} ->
        {:error, "Scope error: #{inspect(err)}"}

      {:error, :owner_required} ->
        {:error, "owner_id is required and could not be derived from the auth token"}
    end
  end

  defp owner(args, ctx) do
    case Args.get(args, :owner_id) || Resolve.current_user_id(ctx) do
      nil -> {:error, :owner_required}
      id -> {:ok, id}
    end
  end
end
