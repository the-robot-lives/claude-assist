defmodule Therobotplans.Domains.Personal.RecurrenceTest do
  @moduledoc """
  Pure recurrence date-math (WS-A US-011 §7). No Repo — every case is calendar
  arithmetic, so it runs without the shared test DB. Rules are plain maps
  (Recurrence tolerates struct or attrs map).
  """
  use ExUnit.Case, async: true

  alias Therobotplans.Domains.Personal.Recurrence

  defp d(iso), do: Date.from_iso8601!(iso)

  describe "next_occurrence/2" do
    test "T-1 daily advances one day" do
      assert {:ok, ~D[2026-07-23]} =
               Recurrence.next_occurrence(%{freq: "daily", interval: 1}, d("2026-07-22"))
    end

    test "daily honors interval > 1" do
      assert {:ok, ~D[2026-07-25]} =
               Recurrence.next_occurrence(%{freq: "daily", interval: 3}, d("2026-07-22"))
    end

    test "T-2 weekdays skips the weekend (Fri -> Mon)" do
      rule = %{freq: "weekly", interval: 1, by_day: ~w(MO TU WE TH FR)}
      # 2026-07-24 is a Friday.
      assert {:ok, ~D[2026-07-27]} = Recurrence.next_occurrence(rule, d("2026-07-24"))
    end

    test "T-3 weekly by_day advances to next matching weekday" do
      rule = %{freq: "weekly", interval: 1, by_day: ["TU"]}
      # 2026-07-21 is a Tuesday -> next Tuesday.
      assert {:ok, ~D[2026-07-28]} = Recurrence.next_occurrence(rule, d("2026-07-21"))
    end

    test "T-4 biweekly skips the intervening week (interval=2)" do
      rule = %{freq: "weekly", interval: 2, by_day: ["WE"]}
      # 2026-07-22 is a Wednesday; +1 week (07-29) is an off-week -> 08-05.
      assert {:ok, ~D[2026-08-05]} = Recurrence.next_occurrence(rule, d("2026-07-22"))
    end

    test "T-5 monthly clamps a month-end anchor (Jan 31 -> Feb 28)" do
      rule = %{freq: "monthly", interval: 1, by_month_day: [31]}
      assert {:ok, ~D[2026-02-28]} = Recurrence.next_occurrence(rule, d("2026-01-31"))
    end

    test "monthly uses anchor day when by_month_day is empty" do
      rule = %{freq: "monthly", interval: 1}
      assert {:ok, ~D[2026-03-15]} = Recurrence.next_occurrence(rule, d("2026-02-15"))
    end

    test "monthly -1 means last day of the target month" do
      rule = %{freq: "monthly", interval: 1, by_month_day: [-1]}
      assert {:ok, ~D[2026-03-31]} = Recurrence.next_occurrence(rule, d("2026-02-15"))
    end

    test "date arithmetic is DST-immune (bare dates never shift)" do
      # US DST begins 2026-03-08; a monthly advance across it lands on the exact
      # calendar day with no off-by-one.
      rule = %{freq: "monthly", interval: 1, by_month_day: [10]}
      assert {:ok, ~D[2026-03-10]} = Recurrence.next_occurrence(rule, d("2026-02-10"))
    end

    test "T-6 until exhausted returns :series_complete" do
      rule = %{freq: "daily", interval: 1, until: d("2026-07-22")}
      # next would be 07-23, past `until` -> series complete.
      assert :series_complete = Recurrence.next_occurrence(rule, d("2026-07-22"))
    end

    test "within until returns the date" do
      rule = %{freq: "daily", interval: 1, until: d("2026-07-31")}
      assert {:ok, ~D[2026-07-23]} = Recurrence.next_occurrence(rule, d("2026-07-22"))
    end
  end

  describe "expand/2" do
    test "daily fills the inclusive range" do
      dates = Recurrence.expand(%{freq: "daily", interval: 1}, Date.range(d("2026-07-22"), d("2026-07-25")))
      assert dates == [d("2026-07-22"), d("2026-07-23"), d("2026-07-24"), d("2026-07-25")]
    end

    test "weekly by_day only yields matching weekdays in range" do
      rule = %{freq: "weekly", interval: 1, by_day: ["WE"]}
      dates = Recurrence.expand(rule, Date.range(d("2026-07-20"), d("2026-08-10")))
      # Wednesdays: 22 Jul, 29 Jul, 05 Aug.
      assert dates == [d("2026-07-22"), d("2026-07-29"), d("2026-08-05")]
    end
  end

  describe "preset_to_rule/3" do
    test "named presets compile to rule attrs" do
      anchor = d("2026-07-22")
      assert {:ok, %{freq: "daily", interval: 1}} = Recurrence.preset_to_rule("daily", anchor, "Etc/UTC")

      assert {:ok, %{freq: "weekly", by_day: ~w(MO TU WE TH FR)}} =
               Recurrence.preset_to_rule("weekdays", anchor, "Etc/UTC")

      assert {:ok, %{freq: "weekly", by_day: ["WE"]}} =
               Recurrence.preset_to_rule("weekly", anchor, "Etc/UTC")

      assert {:ok, %{freq: "weekly", interval: 2, by_day: ["WE"]}} =
               Recurrence.preset_to_rule("biweekly", anchor, "Etc/UTC")

      assert {:ok, %{freq: "monthly", by_month_day: [22]}} =
               Recurrence.preset_to_rule("monthly", anchor, "Etc/UTC")
    end

    test "custom / unknown is not a preset" do
      anchor = d("2026-07-22")
      assert {:error, :unknown_preset} = Recurrence.preset_to_rule("custom", anchor, "Etc/UTC")
      assert {:error, :unknown_preset} = Recurrence.preset_to_rule("yearly", anchor, "Etc/UTC")
    end
  end

  describe "parse_shorthand/2" do
    test "resolves relative phrases in UTC" do
      today = Date.utc_today()
      assert {:ok, ^today} = Recurrence.parse_shorthand("today", "Etc/UTC")
      assert {:ok, tomorrow} = Recurrence.parse_shorthand("tomorrow", "Etc/UTC")
      assert tomorrow == Date.add(today, 1)
      assert {:ok, in3} = Recurrence.parse_shorthand("in 3 days", "Etc/UTC")
      assert in3 == Date.add(today, 3)
    end

    test "passes through an ISO date" do
      assert {:ok, ~D[2026-07-22]} = Recurrence.parse_shorthand("2026-07-22", "Etc/UTC")
    end

    test "resolves next <weekday> strictly forward" do
      # Anchor the assertion on a known today via arithmetic: next occurrence is
      # 1..7 days out and lands on the requested weekday.
      {:ok, date} = Recurrence.parse_shorthand("next monday", "Etc/UTC")
      assert Date.day_of_week(date) == 1
      assert Date.diff(date, Date.utc_today()) in 1..7
    end

    test "rejects unparseable input" do
      assert {:error, _} = Recurrence.parse_shorthand("the second thursday after payday", "Etc/UTC")
    end
  end

  describe "today_in_zone/1 and weekday_code/1" do
    test "falls back to UTC when tz is nil/unknown" do
      assert Recurrence.today_in_zone(nil) == Date.utc_today()
      # An unknown/absent tz db must not crash — falls back to UTC.
      assert %Date{} = Recurrence.today_in_zone("Mars/Olympus_Mons")
    end

    test "weekday_code maps day-of-week" do
      assert Recurrence.weekday_code(~D[2026-07-22]) == "WE"
      assert Recurrence.weekday_code(~D[2026-07-27]) == "MO"
    end
  end
end
