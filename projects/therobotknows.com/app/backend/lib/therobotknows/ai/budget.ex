defmodule Therobotknows.AI.Budget do
  @moduledoc "Generation budget enforcement (US-079)."

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Schema.AI.UserPreference

  def get_or_create_prefs(user_id) do
    case Repo.get_by(UserPreference, user_id: user_id) do
      nil ->
        %UserPreference{}
        |> UserPreference.changeset(%{
          user_id: user_id,
          model: "default",
          monthly_budget_cents: 1000,
          settings: %{},
          updated_at: now()
        })
        |> Repo.insert!()

      pref ->
        pref
    end
  end


  def update_prefs(user_id, attrs) do
    pref = get_or_create_prefs(user_id)

    pref
    |> UserPreference.changeset(%{
      model: Map.get(attrs, "model") || Map.get(attrs, :model) || pref.model,
      monthly_budget_cents:
        Map.get(attrs, "monthly_budget_cents") || Map.get(attrs, :monthly_budget_cents) ||
          pref.monthly_budget_cents,
      settings: Map.get(attrs, "settings") || Map.get(attrs, :settings) || pref.settings,
      updated_at: now()
    })
    |> Repo.update()
  end

  def check_budget(user_id) do
    pref = get_or_create_prefs(user_id)
    period = period_ym()
    used = usage_for(user_id, period)

    if used >= pref.monthly_budget_cents do
      {:error, :budget_exceeded}
    else
      :ok
    end
  end

  def usage_summary(user_id) do
    pref = get_or_create_prefs(user_id)
    period = period_ym()
    used = usage_for(user_id, period)

    %{
      model: pref.model,
      monthly_budget_cents: pref.monthly_budget_cents,
      used_cents: used,
      remaining_cents: max(0, pref.monthly_budget_cents - used),
      period: period,
      settings: pref.settings || %{}
    }
  end

  def record_usage(nil, _universe_id, _gen_id, _cost, _tokens), do: :ok

  def record_usage(user_id, universe_id, generation_id, cost_cents, tokens) do
    Repo.insert_all("generation_usage", [
      %{
        id: Ecto.UUID.generate(),
        user_id: user_id,
        universe_id: universe_id,
        generation_id: generation_id,
        cost_cents: cost_cents || 0,
        tokens: tokens || 0,
        period_ym: period_ym(),
        inserted_at: now()
      }
    ])

    :ok
  end

  defp usage_for(user_id, period) do
    sql = """
    SELECT COALESCE(SUM(cost_cents), 0) FROM generation_usage
    WHERE user_id = $1::uuid AND period_ym = $2
    """

    case Ecto.Adapters.SQL.query(Repo, sql, [user_id, period]) do
      {:ok, %{rows: [[sum]]}} -> sum
      _ -> 0
    end
  end

  defp period_ym do
    {{y, m, _}, _} = :calendar.universal_time()
    "#{y}-#{String.pad_leading(Integer.to_string(m), 2, "0")}"
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:microsecond)
end
