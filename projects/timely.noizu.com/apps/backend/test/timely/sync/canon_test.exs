defmodule Timely.Sync.CanonTest do
  @moduledoc """
  The SYNC-PROTOCOL section 14 conformance gate.

  This suite asserts `apps/shared/contracts/canon-fixtures.json` case for case.
  It is not an ordinary unit test: a `canon()` divergence does not throw, does
  not log and does not fail a sync, it just silently mints two ids for one
  client, so this file is the only thing standing between three hand-written
  implementations and weeks of quietly forked taxonomy rows.

  Expectations are read from the fixture and never restated here. A hand-written
  expectation that happens to match a buggy implementation is worse than no test.
  """
  use ExUnit.Case, async: true

  alias Timely.Sync.Canon

  @fixture_path Path.expand("../../../../shared/contracts/canon-fixtures.json", __DIR__)
  @external_resource @fixture_path

  @fixtures @fixture_path |> File.read!() |> Jason.decode!()

  @workspace_id @fixtures["workspace_id"]
  @canon_cases @fixtures["canon_cases"]
  @composite_cases @fixtures["composite_cases"]

  describe "fixture file" do
    test "is the version this implementation was written against" do
      assert @fixtures["version"] == "1.0.0"
      assert @fixtures["generated_for_contract_version"] == "1.0.0-draft.1"
    end

    test "carries the case counts the conformance gate expects" do
      # A FLOOR, not an equality: catches a fixture that failed to load,
      # truncated, or silently emptied (which would otherwise make every
      # `for ... <- @canon_cases` test below pass by iterating nothing),
      # without coupling this suite to the exact corpus size. Growing the
      # fixture needs no change here; only shrinkage below the floor fails.
      assert length(@canon_cases) >= 65
      assert length(@composite_cases) >= 8
    end
  end

  describe "code point table conformance" do
    # The behavioural cases above only prove agreement on the code points
    # they happen to exercise. A transcription slip on a code point no case
    # touches would pass every test above and still silently mint a duplicate
    # on this platform. These three diff Canon's actual tables - the same
    # ones canon/1 consults, not a second hand-copied list - against the
    # fixture's declared blocks directly.

    test "strip table matches strip_code_points in the fixture" do
      expected = @fixtures["strip_code_points"] |> Enum.map(&parse_codepoint/1) |> MapSet.new()
      assert Canon.strip_code_points() == expected
    end

    test "whitespace table matches whitespace_code_points in the fixture" do
      expected =
        @fixtures["whitespace_code_points"] |> Enum.map(&parse_codepoint/1) |> MapSet.new()

      assert Canon.whitespace_code_points() == expected
    end

    test "quote table matches quote_code_points in the fixture" do
      expected =
        for {token, <<char::utf8>>} <- @fixtures["quote_code_points"], into: %{} do
          {parse_codepoint(token), char}
        end

      assert Canon.quote_code_points() == expected
    end

    test "ZWNJ and ZWJ are never in the strip table" do
      refute MapSet.member?(Canon.strip_code_points(), 0x200C)
      refute MapSet.member?(Canon.strip_code_points(), 0x200D)
    end
  end

  describe "canon/1 conformance" do
    for %{"id" => id, "group" => group, "input" => input} = fixture <- @canon_cases do
      @fixture fixture

      test "#{id} (#{group}): #{inspect(input)}" do
        %{
          "input" => input,
          "expected_output" => expected,
          "expected_output_codepoints" => expected_codepoints
        } = @fixture

        actual = Canon.canon(input)

        # Compare code points, not only the string. A terminal, a diff viewer or
        # an editor will happily render a combining mark or a zero-width
        # character as though it were not there, turning a real failure into a
        # passing test.
        assert codepoints(actual) == expected_codepoints,
               """
               canon/1 produced the wrong code points.
                 input:    #{inspect(input)} #{inspect(codepoints(input))}
                 expected: #{inspect(expected)} #{inspect(expected_codepoints)}
                 actual:   #{inspect(actual)} #{inspect(codepoints(actual))}
                 note:     #{@fixture["note"]}
               """

        assert actual == expected
      end
    end
  end

  describe "client id conformance" do
    for %{"id" => id, "input" => input} <- @canon_cases do
      @case_id id

      test "#{id}: client id for #{inspect(input)}" do
        %{"input" => input, "expected_client_id" => expected_id} = fixture = canon_case(@case_id)

        case expected_id do
          nil ->
            # "An empty canonical form is not an entity." The implementation MUST
            # NOT mint an id and MUST NOT create a row (6.1 step 5).
            assert Canon.canon(input) == ""
            assert Canon.blank?(input)
            assert Canon.client_id(@workspace_id, input) == nil

          expected_id ->
            assert Canon.uuid5(@workspace_id, fixture["expected_client_key"]) == expected_id
            assert Canon.client_id(@workspace_id, input) == expected_id
        end
      end
    end
  end

  describe "composite key conformance" do
    for %{"id" => id, "kind" => kind} = fixture <- @composite_cases do
      @fixture fixture

      test "#{id}: #{kind} key" do
        %{"input" => input, "expected_key" => expected_key, "expected_id" => expected_id} =
          @fixture

        {key, id} =
          case @fixture["kind"] do
            "project" ->
              {"project:" <> Canon.canon(input["client_name"]) <> "/" <> Canon.canon(input["name"]),
               Canon.project_id(@workspace_id, input["client_name"], input["name"])}

            "ticket" ->
              {"ticket:" <>
                 Canon.canon(input["client_name"]) <>
                 "/" <> Canon.canon(input["project_name"]) <> "/" <> Canon.canon(input["name"]),
               Canon.ticket_id(
                 @workspace_id,
                 input["client_name"],
                 input["project_name"],
                 input["name"]
               )}
          end

        assert key == expected_key
        assert Canon.uuid5(@workspace_id, expected_key) == expected_id
        assert id == expected_id
      end
    end
  end

  describe "properties the fixture pins by example and the protocol states as rules" do
    test "canon/1 is idempotent across every fixture case" do
      for %{"input" => input} <- @canon_cases do
        once = Canon.canon(input)
        assert Canon.canon(once) == once, "canon/1 is not idempotent for #{inspect(input)}"
      end
    end

    test "nil is the empty canonical form, not a crash" do
      assert Canon.canon(nil) == ""
      assert Canon.blank?(nil)
      assert Canon.client_id(@workspace_id, nil) == nil
    end

    test "the namespace is case-insensitive so an uppercased workspace id converges" do
      assert Canon.client_id(String.upcase(@workspace_id), "Acme") ==
               Canon.client_id(@workspace_id, "Acme")
    end

    test "an absent parent contributes an empty segment rather than dropping one" do
      assert Canon.project_id(@workspace_id, nil, "Internal") ==
               Canon.uuid5(@workspace_id, "project:/internal")
    end

    test "a project with no name of its own is not an entity" do
      assert Canon.project_id(@workspace_id, "Acme", "  ") == nil
      assert Canon.ticket_id(@workspace_id, "Acme", "Redesign", "") == nil
    end
  end

  # Looked up at runtime rather than inlined as a literal, so the compiler does
  # not narrow `expected_client_id` to a binary and warn that the `nil` branch -
  # the four "not an entity" cases - is unreachable.
  defp canon_case(id), do: Enum.find(@canon_cases, &(&1["id"] == id))

  defp codepoints(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&("U+" <> (&1 |> Integer.to_string(16) |> String.pad_leading(4, "0"))))
  end

  # "U+00AD" -> 0x00AD
  defp parse_codepoint("U+" <> hex), do: String.to_integer(hex, 16)
end
