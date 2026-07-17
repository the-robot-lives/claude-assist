Code.require_file("support/conformance.exs", __DIR__)

defmodule Ithkuil.ConformanceTest do
  @moduledoc """
  Golden-vector conformance: every row of ../../conformance/*.jsonl asserted
  in both directions (see conformance/README.md and CODEC.md).
  """
  use ExUnit.Case, async: true

  alias Ithkuil.{Codec, Coord}
  import Ithkuil.TestSupport.Conformance

  describe "codec_units.jsonl" do
    test "term ser/de and integer ranking, both directions" do
      vectors = vectors("codec_units.jsonl")
      assert vectors != []

      for row <- vectors do
        assert row["kind"] == "term"
        term = json_term(row["term"])
        bytes = hex!(row["bytes"])
        integer = String.to_integer(row["integer"])

        # serialize
        assert Codec.encode_term(term) == bytes,
               "encode_term mismatch for #{inspect(row["term"])}"

        # strict decode, no trailing bytes
        assert {:ok, ^term, <<>>} = Codec.decode_term(bytes)

        # ranking both ways
        assert Codec.rank(bytes) == integer
        assert {:ok, ^bytes} = Codec.unrank(integer)
        assert Codec.term_to_integer(term) == integer
        assert {:ok, ^term} = Codec.integer_to_term(integer)
      end
    end
  end

  describe "coordinate_to_integer.jsonl" do
    test "coordinate <-> bytes <-> integer, both directions" do
      vectors = vectors("coordinate_to_integer.jsonl")
      assert vectors != []

      for row <- vectors do
        assert {:ok, coord} = Coord.from_wire(row["coordinate"])
        bytes = hex!(row["bytes"])
        integer_string = row["integer"]

        # coordinate -> bytes -> coordinate
        assert Codec.encode_word(coord) == bytes
        assert {:ok, ^coord} = Codec.decode_word(bytes)

        # coordinate -> integer string -> coordinate
        assert {:ok, ^integer_string} = Ithkuil.to_integer_string(coord)
        assert {:ok, ^coord} = Ithkuil.from_integer_string(integer_string)

        # wire round-trip is exact (vector coordinates are canonical)
        assert Coord.to_wire(coord) == row["coordinate"]
      end
    end
  end

  describe "invalid_inputs.jsonl" do
    test "every invalid input is rejected with the expected error class" do
      vectors = vectors("invalid_inputs.jsonl")
      assert vectors != []

      for row <- vectors do
        expected = String.to_atom(row["error"])

        result =
          case row["kind"] do
            "integer_string" -> Ithkuil.from_integer_string(row["value"])
            "bytes" -> row["value"] |> hex!() |> Codec.decode_word()
            "coordinate" -> Coord.new(row["value"])
          end

        assert error_class(result) == expected,
               "expected #{expected} for #{inspect(row)}, got #{inspect(result)}"
      end
    end
  end

  describe "latin_to_coordinate.jsonl" do
    test "romanization profile core-v1 vectors, both directions" do
      vectors = vectors("latin_to_coordinate.jsonl")
      assert vectors != []

      for row <- vectors do
        case row do
          %{"error" => error} ->
            expected = String.to_atom(error)
            result = Ithkuil.from_latin(row["latin"])

            assert match?({:error, {^expected, _detail}}, result),
                   "expected #{error} for #{inspect(row["latin"])}, got #{inspect(result)}"

          %{"coordinate" => wire, "canonical" => canonical} ->
            # from_latin(latin) == coordinate
            assert {:ok, coord} = Ithkuil.from_latin(row["latin"])
            assert Coord.to_wire(coord) == wire
            assert {:ok, ^wire} = Ithkuil.to_wire(coord)

            # to_latin(coordinate) == canonical (wire input canonicalized on entry)
            assert {:ok, ^canonical} = Ithkuil.to_latin(wire)
            assert {:ok, ^canonical} = Ithkuil.to_latin(coord)

            # round-trip law: from_latin(to_latin(c)) == c
            assert {:ok, ^coord} = Ithkuil.from_latin(canonical)
        end
      end
    end
  end

  describe "CODEC.md worked example" do
    test "empty word ranks to 8606843649" do
      empty = {:ithkuil_word, 1, []}
      assert Codec.encode_word(empty) == <<0x01, 0x00, 0x01, 0x02, 0x00>>
      assert Ithkuil.to_integer(empty) == {:ok, 8_606_843_649}
      assert Ithkuil.from_integer_string("8606843649") == {:ok, empty}
    end
  end
end
