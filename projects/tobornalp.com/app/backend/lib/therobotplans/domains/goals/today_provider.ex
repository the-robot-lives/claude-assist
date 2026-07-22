defmodule Therobotplans.Domains.Goals.TodayProvider do
  @moduledoc """
  Today read-model provider for goals/OKRs (WS-I, US-069) — see
  `project-management/contracts/today-read-model.md` §2/§3/§7.

  Surfaces the user's objectives that **need attention** (`at_risk`/`off_track`),
  not every active objective, mapped to the canonical Today `entry` envelope.

  **Inert-but-correct:** until WS-L registers it and lands the aggregator refactor
  this module is a compiled no-op. It implements the (forthcoming)
  `Therobotplans.Today.Provider` behaviour **by shape** — `@behaviour` is
  intentionally omitted while that behaviour module is unshipped, so this lane
  compiles clean and the provider activates the moment it is registered.

  Register via a WS-L interface ticket (do NOT edit config from this lane):

      # config/config.exs  (WS-L owns this key)
      config :therobotplans, Therobotplans.Today,
        providers: [..., Therobotplans.Domains.Goals.TodayProvider]
  """
  import Ecto.Query

  alias Therobotplans.Repo
  alias Therobotplans.Schema.Objective
  alias Therobotplans.Domains.Goals

  @source :goal
  @default_limit 25

  @doc "Stable atom identifying this source (§2 table)."
  def source, do: @source

  @doc """
  The user's at-risk / off-track objectives as Today entries. Org-scoped when
  `opts[:org_id]` is set. Read-only; returns `[]` on empty/unauthorized, never raises.
  """
  def read(user_id, opts \\ []) do
    limit = opts[:limit] || @default_limit
    org_id = opts[:org_id]

    Objective
    |> where([o], o.owner_id == ^user_id and o.status in ~w(at_risk off_track))
    |> scope_org(org_id)
    |> order_by([o], desc: o.updated_at)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(&entry/1)
  rescue
    _ -> []
  end

  @doc "Event types that dirty this source's slice (optional behaviour callback)."
  def dirty_on, do: [:objective_off_track]

  defp scope_org(query, nil), do: query
  defp scope_org(query, org_id), do: where(query, [o], o.organization_id == ^org_id)

  defp entry(o) do
    progress = Goals.progress_for(o)
    pct = progress |> Decimal.mult(100) |> Decimal.round(0) |> Decimal.to_integer()

    %{
      id: "#{@source}:#{o.id}",
      source: @source,
      source_ref: %{type: :objective, id: o.id},
      kind: :goal,
      title: o.title,
      subtitle: "#{pct}% · #{o.status}",
      link: "/app/#{o.organization_id}/goals/#{o.id}",
      due_at: nil,
      status: o.status,
      priority: priority_for(o.status),
      weight: nil,
      sort_hint: nil,
      meta: %{level: o.level, rollup_strategy: o.rollup_strategy, progress: progress}
    }
  end

  defp priority_for("off_track"), do: :high
  defp priority_for("at_risk"), do: :medium
  defp priority_for(_), do: nil
end
