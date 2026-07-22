defmodule Therobotplans.Domains.Goals.RollupTest do
  @moduledoc """
  Pure rollup-math unit tests (US-069) — no DB. Covers direction + clamp
  (FR-4), weighted_avg / min_children combination (FR-2/FR-3), the custom
  resolver fallback (FR-3), and the pure cycle/depth guard (FR-5/FR-6).
  """
  use ExUnit.Case, async: true

  alias Therobotplans.Domains.Goals
  alias Therobotplans.Domains.Goals.Rollup

  defp d(s), do: Decimal.new(s)
  defp contrib(frac, weight), do: %{frac: d(frac), weight: d(weight)}
  defp eq?(a, b), do: Decimal.equal?(a, b)

  describe "kr_fraction/3 — direction + clamp (FR-4)" do
    test "higher_better is current/target" do
      assert eq?(Rollup.kr_fraction(d("50"), d("100"), "higher_better"), d("0.5"))
    end

    test "lower_better is 1 - current/target" do
      assert eq?(Rollup.kr_fraction(d("40"), d("100"), "lower_better"), d("0.6"))
    end

    test "exceeding target clamps to exactly 1.0 (never pushes a parent > 100%)" do
      assert eq?(Rollup.kr_fraction(d("150"), d("100"), "higher_better"), d("1"))
    end

    test "lower_better below baseline clamps to 0" do
      assert eq?(Rollup.kr_fraction(d("250"), d("100"), "lower_better"), d("0"))
    end

    test "target 0 is 0 (undefined)" do
      assert eq?(Rollup.kr_fraction(d("5"), d("0"), "higher_better"), d("0"))
    end
  end

  describe "combine/2 — weighted_avg (FR-2/FR-3)" do
    test "normalizes by total present weight" do
      # (0.8·2 + 0.4·1 + 0.6·1) / (2+1+1) = 2.6/4 = 0.65
      contribs = [contrib("0.8", "2"), contrib("0.4", "1"), contrib("0.6", "1")]
      assert eq?(Rollup.combine("weighted_avg", contribs), d("0.65"))
    end

    test "empty contributor set is 0" do
      assert eq?(Rollup.combine("weighted_avg", []), d("0"))
    end
  end

  describe "combine/2 — min_children (FR-3)" do
    test "is the minimum contributor fraction" do
      contribs = [contrib("0.8", "2"), contrib("0.4", "1"), contrib("0.6", "1")]
      assert eq?(Rollup.combine("min_children", contribs), d("0.4"))
    end
  end

  describe "resolve/2 — custom seam (FR-3)" do
    test "custom falls back to weighted_avg when no resolver is registered" do
      contribs = [contrib("0.8", "2"), contrib("0.4", "1")]
      obj = %{rollup_strategy: "custom"}
      # (0.8·2 + 0.4·1)/3 = 2.0/3
      assert eq?(Rollup.resolve(obj, contribs), Decimal.div(d("2.0"), d("3")))
    end

    test "known strategy routes through combine" do
      contribs = [contrib("0.2", "1"), contrib("0.9", "1")]
      assert eq?(Rollup.resolve(%{rollup_strategy: "min_children"}, contribs), d("0.2"))
    end
  end

  describe "hierarchy_check/4 — cycle + depth (FR-5/FR-6)" do
    test "nil parent (root) is always allowed" do
      assert Goals.hierarchy_check("a", nil, [], 3) == :ok
    end

    test "self-parent is a cycle" do
      assert Goals.hierarchy_check("a", "a", [], 1) == {:error, :cycle}
    end

    test "reparenting under a descendant is a cycle" do
      # moved "a" appears in the target's ancestor chain
      assert Goals.hierarchy_check("a", "b", ["b", "a", "root"], 1) == {:error, :cycle}
    end

    test "a lone node under a shallow parent is allowed" do
      assert Goals.hierarchy_check("a", "b", ["b"], 1) == :ok
    end

    test "a chain reaching exactly depth 6 succeeds" do
      # parent at depth 5 (5 ancestors incl. parent) + lone node (height 1) = 6
      assert Goals.hierarchy_check("a", "p5", ["p5", "p4", "p3", "p2", "p1"], 1) == :ok
    end

    test "the 7th level is rejected as max_depth" do
      # parent at depth 6 + lone node = 7
      assert Goals.hierarchy_check("a", "p6", ["p6", "p5", "p4", "p3", "p2", "p1"], 1) ==
               {:error, :max_depth}
    end

    test "moving a 2-deep subtree under a depth-5 node (would be 7) is rejected" do
      assert Goals.hierarchy_check("a", "p5", ["p5", "p4", "p3", "p2", "p1"], 2) ==
               {:error, :max_depth}
    end
  end
end
