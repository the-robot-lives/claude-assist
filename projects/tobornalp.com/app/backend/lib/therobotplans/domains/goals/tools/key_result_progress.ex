defmodule Therobotplans.Domains.Goals.Tools.KeyResultProgress do
  use Noizu.MCP.Server.Tool,
    name: "KeyResult.Progress",
    description: "Force-recompute an item-backed key result's current_value from its linked items, and return the recomputed value.",
    hidden: true,
    category: "Goals",
    annotations: [read_only_hint: true]

  alias Therobotplans.Domains.Goals
  alias Therobotplans.MCP.Args

  input do
    field :key_result, :string, required: true, description: "Key result UUID"
  end

  @impl true
  def call(args, _ctx) do
    kr_id = Args.get(args, :key_result)
    Goals.recompute_progress(kr_id)

    case Goals.get_key_result(kr_id) do
      nil -> {:error, "Key result not found"}
      kr -> {:ok, %{id: kr.id, current_value: kr.current_value, target_value: kr.target_value}}
    end
  end
end
