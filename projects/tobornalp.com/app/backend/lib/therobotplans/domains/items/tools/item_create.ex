defmodule Therobotplans.Domains.Items.Tools.ItemCreate do
  use Noizu.MCP.Server.Tool,
    name: "Item.Create",
    description: "Create a new item with typed fields.",
    hidden: true,
    category: "Items"

  input_schema %{
    "type" => "object",
    "properties" => %{
      "organization" => %{"type" => "string", "description" => "Organization slug or UUID (required)"},
      "title" => %{"type" => "string", "description" => "Item title"},
      "description" => %{"type" => "string", "description" => "Item description (markdown)"},
      "item_type" => %{"type" => "string", "description" => "Type slug: epic, user_story, prd, bug, task, documentation, research, subtask (default: task)"},
      "status" => %{"type" => "string", "description" => "Initial status (default: first in type workflow)"},
      "priority" => %{"type" => "string", "description" => "low, medium, high, critical"},
      "assignee" => %{"type" => "string", "description" => "Assignee persona slug"},
      "reporter" => %{"type" => "string", "description" => "Reporter persona slug"},
      "project" => %{"type" => "string", "description" => "Optional project slug or UUID to scope this item to"},
      "queue_id" => %{"type" => "string", "description" => "Queue UUID"},
      "parent_id" => %{"type" => "string", "description" => "Parent item UUID"},
      "custom_fields" => %{"type" => "object", "description" => "Type-specific field values as {slug: value}"}
    },
    "required" => ["organization", "title"]
  }

  alias Therobotplans.Domains.Items
  alias Therobotplans.MCP.{Args, Resolve}

  @impl true
  def call(args, _ctx) do
    org_ref = Args.get(args, :organization)
    project_ref = Args.get(args, :project) || Args.get(args, :project_id)

    with {:org, org_id} when not is_nil(org_id) <- {:org, Resolve.organization_id(org_ref)},
         {:ok, project_id} <- Resolve.project_in_org(project_ref, org_id) do
      attrs =
        extract(args, ~w(title description item_type status priority assignee reporter queue_id parent_id custom_fields))
        |> Map.put(:organization_id, org_id)
        |> Map.put(:project_id, project_id)
        |> Map.put_new(:item_type, "task")

      case Items.create(attrs) do
        {:ok, item} ->
          {:ok, %{
            id: item.id, title: item.title, item_type: item.item_type,
            status: item.status, priority: item.priority,
            organization_id: item.organization_id, project_id: item.project_id,
            created_at: item.inserted_at
          }}
        {:error, changeset} ->
          {:error, "Failed: #{inspect(changeset.errors)}"}
      end
    else
      {:org, nil} -> {:error, "Organization '#{org_ref}' not found"}
      {:error, :project_not_found} -> {:error, "Project '#{project_ref}' not found"}
      {:error, :project_not_in_org} -> {:error, "Project '#{project_ref}' does not belong to this organization"}
    end
  end

  defp extract(args, keys) do
    Enum.reduce(keys, %{}, fn k, acc ->
      atom_key = String.to_atom(k)
      val = args[atom_key] || args[k]
      if val, do: Map.put(acc, atom_key, val), else: acc
    end)
  end
end
