defmodule Therobotplans.Domains.Goals.Rollup do
  @moduledoc """
  Pure rollup math for objective progress (US-069). Separated from `Goals` so the
  aggregation is unit-testable without a DB, and so `custom` has a pluggable seam
  (a behaviour + resolver, **not** a formula DSL).

  A `contributor` is `%{frac: Decimal.t(), weight: Decimal.t()}` where `frac` is an
  already-clamped `[0,1]` progress fraction (from a child objective or an own KR)
  and `weight` is its relative contribution to this objective's rollup.
  """

  @type contributor :: %{frac: Decimal.t(), weight: Decimal.t()}

  @doc """
  Behaviour for a `custom` rollup resolver — the seam. Register one via

      config :therobotplans, #{inspect(__MODULE__)}, resolver: MyResolver

  Until a resolver is registered, `custom` falls back to `weighted_avg`.
  """
  @callback resolve(objective :: map(), contributors :: [contributor()]) :: Decimal.t()

  @zero Decimal.new("0")
  @one Decimal.new("1")

  @doc """
  Direction-aware KR fraction, clamped to `[0,1]`.

    * `higher_better` → `current / target`
    * `lower_better`  → `1 - (current / target)`
    * `target == 0`   → `0`

  Clamping guarantees a KR that exceeds target contributes exactly `1.0` and can
  never push a parent above 100% (FR-4).
  """
  @spec kr_fraction(Decimal.t(), Decimal.t(), String.t()) :: Decimal.t()
  def kr_fraction(current, target, direction) do
    cond do
      Decimal.equal?(target, @zero) ->
        @zero

      direction == "lower_better" ->
        clamp01(Decimal.sub(@one, Decimal.div(current, target)))

      true ->
        clamp01(Decimal.div(current, target))
    end
  end

  @doc "Clamp a Decimal to `[0,1]`."
  @spec clamp01(Decimal.t()) :: Decimal.t()
  def clamp01(d) do
    cond do
      Decimal.lt?(d, @zero) -> @zero
      Decimal.gt?(d, @one) -> @one
      true -> d
    end
  end

  @doc """
  Combine a non-empty contributor list under a strategy string. Empty list → `0`.

    * `weighted_avg` — `Σ(frac·weight) / Σ(weight)` over present contributors
    * `min_children` — `min(frac)` over present contributors
    * `custom` / unknown — falls back to `weighted_avg` (the `custom` resolver seam
      is entered through `resolve/2`, which has the objective struct)
  """
  @spec combine(String.t(), [contributor()]) :: Decimal.t()
  def combine(_strategy, []), do: @zero
  def combine("min_children", contributors), do: min_children(contributors)
  def combine(_strategy, contributors), do: weighted_avg(contributors)

  @doc """
  Strategy dispatch with the full objective — the engine's entry point. Reads the
  objective's `:rollup_strategy`; routes `custom` to a registered resolver module
  (falling back to `weighted_avg`). Empty contributors → `0`.
  """
  @spec resolve(map(), [contributor()]) :: Decimal.t()
  def resolve(_objective, []), do: @zero

  def resolve(%{rollup_strategy: "custom"} = objective, contributors) do
    case resolver() do
      nil -> weighted_avg(contributors)
      mod -> mod.resolve(objective, contributors)
    end
  end

  def resolve(%{rollup_strategy: strategy}, contributors) when is_binary(strategy) do
    combine(strategy, contributors)
  end

  def resolve(_objective, contributors), do: weighted_avg(contributors)

  # ── internals ──────────────────────────────────────────────────

  defp weighted_avg(contributors) do
    {sum, total} =
      Enum.reduce(contributors, {@zero, @zero}, fn %{frac: f, weight: w}, {s, t} ->
        {Decimal.add(s, Decimal.mult(f, w)), Decimal.add(t, w)}
      end)

    if Decimal.equal?(total, @zero), do: @zero, else: Decimal.div(sum, total)
  end

  defp min_children(contributors) do
    contributors
    |> Enum.map(& &1.frac)
    |> Enum.reduce(fn f, acc -> if Decimal.lt?(f, acc), do: f, else: acc end)
  end

  defp resolver do
    :therobotplans
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:resolver)
  end
end
