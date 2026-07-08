defmodule Therobotplans.Domains.Goals.Tools.KeyResultUpdate do
  use Noizu.MCP.Server.Tool,
    name: "KeyResult.Update",
    description: "Update a key result. For a manual KR, set current_value; for an auto_progress KR, current_value is ignored (recomputed from items).",
    hidden: true,
    category: "Goals"

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.Args

  input do
    field :key_result, :string, required: true, description: "Key result UUID"
    field :title, :string, description: "New title"
    field :current_value, :number, description: "New current value (manual KR only)"
    field :target_value, :number, description: "New target value"
    field :status, :string, description: "on_track|at_risk|behind|completed"
    field :due_on, :string, description: "Due date (YYYY-MM-DD)"
  end

  @impl true
  def call(args, _ctx) do
    attrs =
      Args.take(args, [:title, :current_value, :target_value, :status])
      |> Map.put(:due_on, parse_date(Args.get(args, :due_on)))

    case Goals.update_key_result(Args.get(args, :key_result), attrs) do
      {:ok, kr} -> {:ok, %{id: kr.id, current_value: kr.current_value, target_value: kr.target_value, status: kr.status}}
      {:error, :not_found} -> {:error, "Key result not found"}
      {:error, cs} -> {:error, "Failed: #{inspect(cs.errors)}"}
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> nil
    end
  end
end
