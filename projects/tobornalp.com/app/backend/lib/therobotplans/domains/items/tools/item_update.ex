defmodule Therobotplans.Domains.Items.Tools.ItemUpdate do
  use Noizu.MCP.Server.Tool,
    name: "Item.Update",
    description: "Update item fields (partial update, custom_fields are merged).",
    hidden: true,
    category: "Items"

  input_schema %{
    "type" => "object",
    "properties" => %{
      "item_id" => %{"type" => "string", "description" => "Item UUID"},
      "title" => %{"type" => "string", "description" => "New title"},
      "description" => %{"type" => "string", "description" => "New description"},
      "status" => %{"type" => "string", "description" => "New status"},
      "priority" => %{"type" => "string", "description" => "New priority"},
      "assignee" => %{"type" => "string", "description" => "New assignee"},
      "project_id" => %{"type" => "string", "description" => "New project UUID"},
      "queue_id" => %{"type" => "string", "description" => "New queue UUID"},
      "parent_id" => %{"type" => "string", "description" => "New parent UUID"},
      "custom_fields" => %{"type" => "object", "description" => "Fields to merge into existing custom_fields"}
    },
    "required" => ["item_id"]
  }

  alias Therobotplans.Domains.Items

  @impl true
  def call(args, _ctx) do
    item_id = args["item_id"]
    attrs = extract(args, ~w(title description status priority assignee project_id queue_id parent_id custom_fields))

    case Items.update(item_id, attrs) do
      {:ok, item} ->
        {:ok, %{id: item.id, title: item.title, status: item.status,
                priority: item.priority, updated_at: item.updated_at}}
      {:error, :not_found} ->
        {:error, "Item '#{item_id}' not found"}
      {:error, changeset} ->
        {:error, "Failed: #{inspect(changeset.errors)}"}
    end
  end

  defp extract(args, keys) do
    Enum.reduce(keys, %{}, fn k, acc ->
      val = args[k]
      if val, do: Map.put(acc, String.to_atom(k), val), else: acc
    end)
  end
end
