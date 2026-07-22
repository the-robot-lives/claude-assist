defmodule Therobotplans.Domains.Personal.Recurrence do
  @moduledoc """
  Pure recurrence date math for personal todos (WS-A US-011). No Repo, no
  side-effects — every function takes/returns plain `Date`s and rule structs so
  it is trivially unit-testable and timezone-arithmetic-free where it can be.

  `due_date` is a bare calendar date (no clock time), so occurrence arithmetic
  (add days / weeks / months) is DST-immune: we never cross a wall-clock
  boundary. Timezone only enters when resolving *"today"* / relative phrases
  (`today_in_zone/1`, `parse_shorthand/2`), where it decides which calendar day a
  user is on.
  """

  alias Therobotplans.Schema.RecurrenceRule

  @day_codes ~w(MO TU WE TH FR SA SU)
  # Date.day_of_week is 1=Mon..7=Sun; index into @day_codes with (dow - 1).

  @type rule :: RecurrenceRule.t() | map()

  @doc """
  Next occurrence strictly after `from`, honoring the rule. Returns
  `:series_complete` when the rule's `until` is passed. `count` exhaustion is
  the orchestrator's concern (it needs the materialized-count from the DB); this
  function only knows about `until`.
  """
  @spec next_occurrence(rule, Date.t()) :: {:ok, Date.t()} | :series_complete | {:error, term}
  def next_occurrence(rule, %Date{} = from) do
    with {:ok, date} <- do_next(rule, from) do
      case rule_until(rule) do
        %Date{} = until -> if Date.compare(date, until) == :gt, do: :series_complete, else: {:ok, date}
        _ -> {:ok, date}
      end
    end
  end

  @doc "All occurrences within an inclusive date range (calendar/preview; US-017)."
  @spec expand(rule, Date.Range.t()) :: [Date.t()]
  def expand(rule, %Date.Range{first: first, last: last}) do
    # Walk forward from just before `first` collecting occurrences until we pass
    # `last`. Bounded by the range length so a malformed rule can't loop forever.
    max_steps = Date.diff(last, first) + 2
    step_from = Date.add(first, -1)
    collect(rule, step_from, last, max_steps, [])
  end

  defp collect(_rule, _cursor, _last, 0, acc), do: Enum.reverse(acc)

  defp collect(rule, cursor, last, budget, acc) do
    case next_occurrence(rule, cursor) do
      {:ok, date} ->
        if Date.compare(date, last) == :gt,
          do: Enum.reverse(acc),
          else: collect(rule, date, last, budget - 1, [date | acc])

      _ ->
        Enum.reverse(acc)
    end
  end

  @doc """
  Compile a preset name to rule attrs given an anchor date + tz. `custom` is not
  a preset — the caller supplies raw fields for it — so it returns
  `{:error, :unknown_preset}` like any unknown name.
  """
  @spec preset_to_rule(String.t(), Date.t(), String.t()) :: {:ok, map} | {:error, :unknown_preset}
  def preset_to_rule(preset, %Date{} = anchor, tz) do
    base = %{interval: 1, timezone: tz || "Etc/UTC"}

    case preset do
      "daily" ->
        {:ok, Map.merge(base, %{freq: "daily"})}

      "weekdays" ->
        {:ok, Map.merge(base, %{freq: "weekly", by_day: ~w(MO TU WE TH FR)})}

      "weekly" ->
        {:ok, Map.merge(base, %{freq: "weekly", by_day: [weekday_code(anchor)]})}

      "biweekly" ->
        {:ok, Map.merge(base, %{freq: "weekly", interval: 2, by_day: [weekday_code(anchor)]})}

      "monthly" ->
        {:ok, Map.merge(base, %{freq: "monthly", by_month_day: [anchor.day]})}

      _ ->
        {:error, :unknown_preset}
    end
  end

  @doc """
  Minimal relative-date parser resolved in `tz`: `today`, `tomorrow`,
  `next <weekday>`, `in N days`, or an ISO `YYYY-MM-DD`. Full NLP is out of scope.
  """
  @spec parse_shorthand(String.t(), String.t()) :: {:ok, Date.t()} | {:error, term}
  def parse_shorthand(str, tz) when is_binary(str) do
    norm = str |> String.trim() |> String.downcase()
    today = today_in_zone(tz)

    cond do
      norm == "today" ->
        {:ok, today}

      norm == "tomorrow" ->
        {:ok, Date.add(today, 1)}

      Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, norm) ->
        Date.from_iso8601(norm)

      match = Regex.run(~r/^in\s+(\d+)\s+days?$/, norm) ->
        [_, n] = match
        {:ok, Date.add(today, String.to_integer(n))}

      match = Regex.run(~r/^next\s+([a-z]+)$/, norm) ->
        [_, wd] = match
        parse_next_weekday(wd, today)

      true ->
        {:error, :unparseable}
    end
  end

  @doc """
  Today as a calendar `Date` in `tz`. Falls back to UTC when the tz is unknown
  or the runtime lacks a full tz database (default Elixir ships UTC-only) — so a
  bare-date computation never crashes on a named zone.
  """
  @spec today_in_zone(String.t() | nil) :: Date.t()
  def today_in_zone(tz) when is_binary(tz) and tz != "" do
    case DateTime.now(tz) do
      {:ok, dt} -> DateTime.to_date(dt)
      _ -> Date.utc_today()
    end
  end

  def today_in_zone(_), do: Date.utc_today()

  @doc "The MO..SU code for a date's weekday."
  @spec weekday_code(Date.t()) :: String.t()
  def weekday_code(%Date{} = date), do: Enum.at(@day_codes, Date.day_of_week(date) - 1)

  # ── frequency dispatch ────────────────────────────────────────────

  defp do_next(rule, from) do
    case rule_freq(rule) do
      "daily" -> {:ok, Date.add(from, max(rule_interval(rule), 1))}
      "weekly" -> next_weekly(rule, from)
      "monthly" -> next_monthly(rule, from)
      other -> {:error, {:unsupported_freq, other}}
    end
  end

  # Weekly: with no by_day, step whole weeks; with by_day, find the next matching
  # weekday that also lands in an "on" week (week-count from `from` divisible by
  # interval, so biweekly skips the intervening week — T-4).
  defp next_weekly(rule, from) do
    interval = max(rule_interval(rule), 1)
    days = rule_by_day(rule)

    case days do
      [] ->
        {:ok, Date.add(from, 7 * interval)}

      _ ->
        anchor_monday = monday_of(from)

        date =
          Stream.iterate(Date.add(from, 1), &Date.add(&1, 1))
          |> Enum.find(fn d ->
            weekday_code(d) in days and
              rem(div(Date.diff(monday_of(d), anchor_monday), 7), interval) == 0
          end)

        {:ok, date}
    end
  end

  # Monthly: advance `interval` months from `from`, then set the day-of-month from
  # by_month_day (first entry, `-1` = last day), clamped to the target month's
  # length (Jan 31 → Feb 28/29 — T-5). Guarantees strictly-after `from`.
  defp next_monthly(rule, from) do
    day_spec =
      case rule_by_month_day(rule) do
        [d | _] -> d
        _ -> from.day
      end

    date = monthly_from(from, max(rule_interval(rule), 1), day_spec)
    {:ok, date}
  end

  defp monthly_from(from, interval, day_spec) do
    base = add_months(from, interval)
    dim = Date.days_in_month(base)
    day = if day_spec == -1, do: dim, else: min(day_spec, dim)
    candidate = %Date{year: base.year, month: base.month, day: day}

    # Defensive: if clamping produced a date not strictly after `from`, step one
    # more interval (only reachable for pathological interval=0-style inputs).
    if Date.compare(candidate, from) == :gt,
      do: candidate,
      else: monthly_from(base, interval, day_spec)
  end

  # ── date helpers ──────────────────────────────────────────────────

  defp monday_of(%Date{} = d), do: Date.add(d, -(Date.day_of_week(d) - 1))

  # Add whole calendar months, rolling the year and clamping the day to the
  # target month length so no invalid date is ever constructed.
  defp add_months(%Date{year: y, month: m, day: d}, n) do
    total = (y * 12 + (m - 1)) + n
    ny = div(total, 12)
    nm = rem(total, 12) + 1
    dim = Date.days_in_month(%Date{year: ny, month: nm, day: 1})
    %Date{year: ny, month: nm, day: min(d, dim)}
  end

  defp parse_next_weekday(wd, today) do
    long = %{
      "monday" => 1, "tuesday" => 2, "wednesday" => 3, "thursday" => 4,
      "friday" => 5, "saturday" => 6, "sunday" => 7,
      "mon" => 1, "tue" => 2, "wed" => 3, "thu" => 4, "fri" => 5, "sat" => 6, "sun" => 7
    }

    case Map.get(long, wd) do
      nil ->
        {:error, :unparseable}

      target ->
        # Strictly the *next* occurrence of that weekday (1..7 days out).
        offset = rem(target - Date.day_of_week(today) + 7, 7)
        offset = if offset == 0, do: 7, else: offset
        {:ok, Date.add(today, offset)}
    end
  end

  # ── rule field access (tolerates a struct or a plain attrs map) ────

  defp rule_freq(rule), do: to_string(rule_get(rule, :freq))
  defp rule_interval(rule), do: rule_get(rule, :interval) || 1
  defp rule_by_day(rule), do: rule_get(rule, :by_day) || []
  defp rule_by_month_day(rule), do: rule_get(rule, :by_month_day) || []
  defp rule_until(rule), do: rule_get(rule, :until)

  defp rule_get(rule, key) when is_map(rule),
    do: Map.get(rule, key) || Map.get(rule, Atom.to_string(key))
end
