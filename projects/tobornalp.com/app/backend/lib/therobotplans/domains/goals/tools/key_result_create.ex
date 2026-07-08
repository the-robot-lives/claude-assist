defmodule Therobotplans.Domains.Goals.Tools.KeyResultCreate do
  use Noizu.MCP.Server.Tool,
    name: "KeyResult.Create",
    description:
      "Create a key result for an objective. Set auto_progress:true and link items via KeyResult.LinkItem to have its current_value computed from linked item completion.",
    hidden: true,
    category: "Goals"

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.Args

  input do
    field :objective, :string, required: true, description: "Objective UUID"
    field :title, :string, required: true, description: "Key result title"
    field :target_value, :number, description: "Target value (default 100)"
    field :current_value, :number, description: "Starting current value (default 0; ignored when auto_progress)"
    field :unit, :string, description: "Unit of measure (e.g. %, ms, count)"
    field :direction, :string, description: "higher_better (default) | lower_better"
    field :due_on, :string, description: "Due date (YYYY-MM-DD)"
    field :auto_progress, :boolean, default: false, description: "Compute current_value from linked items"
    field :owner_id, :string, description: "Owner user UUID"
  end

  @impl true
  def call(args, _ctx) do
    attrs =
      %{
        objective_id: Args.get(args, :objective),
        title: Args.get(args, :title),
        unit: Args.get(args, :unit),
        direction: Args.get(args, :direction) || "higher_better",
        due_on: parse_date(Args.get(args, :due_on)),
        auto_progress: Args.get(args, :auto_progress) == true,
        owner_id: Args.get(args, :owner_id)
      }
      |> maybe_put(:target_value, Args.get(args, :target_value))
      |> maybe_put(:current_value, Args.get(args, :current_value))

    case Goals.create_key_result(attrs) do
      {:ok, kr} -> {:ok, %{id: kr.id, objective_id: kr.objective_id, title: kr.title, auto_progress: kr.auto_progress}}
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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)
end
