Code.require_file("support/conformance.exs", __DIR__)

defmodule Ithkuil.RoundTripTest do
  @moduledoc """
  Hand-rolled property-style round-trips over ~200 deterministic
  pseudo-random valid coordinates (seeded LCG, no dependencies):

      from_integer(to_integer(c))                       == {:ok, c}
      from_integer_string(to_integer_string(c))         == {:ok, c}
      from_bytes(to_bytes(c))                           == {:ok, c}
      from_wire(to_wire(c))                             == {:ok, c}
      from_wire_json(to_wire_json(c))                   == {:ok, c}
      extract_coordinate(render(to_scene(c), mode))     == {:ok, to_wire(c)}
  """
  use ExUnit.Case, async: true

  alias Ithkuil.{Coord, SVG}
  alias Ithkuil.TestSupport.Gen

  @iterations 200
  @seed 0x1FF7_C0DE

  test "integer and SVG-metadata round-trips hold for #{@iterations} generated coordinates" do
    Enum.reduce(1..@iterations, @seed, fn _i, s ->
      {coord, s} = Gen.coord(s)

      # Generated coordinates are canonical by construction.
      assert Coord.validate(coord) == :ok

      # integer round-trip (exact)
      assert {:ok, integer} = Ithkuil.to_integer(coord)
      assert {:ok, ^coord} = Ithkuil.from_integer(integer)

      # boundary form: unsigned decimal string
      assert {:ok, integer_string} = Ithkuil.to_integer_string(coord)
      assert integer_string == Integer.to_string(integer)
      assert {:ok, ^coord} = Ithkuil.from_integer_string(integer_string)

      # bytes round-trip (strict decode)
      assert {:ok, bytes} = Ithkuil.to_bytes(coord)
      assert {:ok, ^coord} = Ithkuil.from_bytes(bytes)

      # wire and wire-JSON round-trips (lenient-canonicalizing input)
      assert {:ok, wire_form} = Ithkuil.to_wire(coord)
      assert wire_form == Coord.to_wire(coord)
      assert {:ok, ^coord} = Ithkuil.from_wire(wire_form)
      assert {:ok, json} = Ithkuil.to_wire_json(coord)
      assert {:ok, ^coord} = Ithkuil.from_wire_json(json)

      # validate / canonicalize fixpoints on canonical input
      assert {:ok, ^coord} = Ithkuil.validate(coord)
      assert {:ok, ^coord} = Ithkuil.canonicalize(coord)

      # scene -> SVG -> metadata round-trip, both modes
      assert {:ok, model} = Ithkuil.to_scene(coord)
      wire = Coord.to_wire(coord)
      assert model.coordinate == wire

      for mode <- [:compact, :exploded] do
        svg = SVG.render(model, mode)
        assert {:ok, ^wire} = SVG.extract_coordinate(svg)
        assert {:ok, ^coord} = Coord.from_wire(wire)

        assert {:ok, meta} = SVG.extract_metadata(svg)
        assert meta["schema"] == "ithkuil-coordinate/1"
        assert meta["integer"] == integer_string
        assert meta["mode"] == Atom.to_string(mode)
      end

      s
    end)
  end

  test "wire form with empty sockets and unsorted order canonicalizes (empties omitted, sorted)" do
    wire = [
      "ithkuil-word",
      1,
      [["glyph", 0, 17, 1, [[4, nil], [1, ["modifier", 6, 2, [3], []]], [0, nil]]]]
    ]

    assert {:ok, coord} = Coord.from_wire(wire)
    assert coord == {:ithkuil_word, 1, [{:glyph, 0, 17, 1, [{1, {:modifier, 6, 2, [3], []}}]}]}

    # The public lenient entry point agrees with Coord.from_wire.
    assert Ithkuil.from_wire(wire) == {:ok, coord}
    assert Ithkuil.canonicalize(wire) == {:ok, coord}

    # Canonical wire omits the empties: one meaning, one representation.
    assert Coord.to_wire(coord) ==
             ["ithkuil-word", 1, [["glyph", 0, 17, 1, [[1, ["modifier", 6, 2, [3], []]]]]]]
  end

  test "from_wire duplicates are an error, never repaired" do
    wire = [
      "ithkuil-word",
      1,
      [["glyph", 0, 1, 0, [[2, nil], [2, ["modifier", 0, 0, [], []]]]]]
    ]

    assert {:error, {:duplicate_socket, 2}} = Ithkuil.from_wire(wire)
  end

  test "from_wire_json parses wire JSON text and canonicalizes" do
    json =
      ~S(["ithkuil-word", 1, [["glyph", 0, 17, 1, [[4, null], [1, ["modifier", 6, 2, [3], []]], [0, null]]]]])

    assert {:ok, coord} = Ithkuil.from_wire_json(json)
    assert coord == {:ithkuil_word, 1, [{:glyph, 0, 17, 1, [{1, {:modifier, 6, 2, [3], []}}]}]}

    assert {:ok, ~S(["ithkuil-word",1,[["glyph",0,17,1,[[1,["modifier",6,2,[3],[]]]]]]])} =
             Ithkuil.to_wire_json(coord)

    assert {:error, {:invalid_structure, _}} = Ithkuil.from_wire_json("not json")
    assert {:error, {:invalid_structure, _}} = Ithkuil.from_wire_json(42)
  end

  test "validate is strict; canonicalize repairs" do
    loose = {:ithkuil_word, 1, [{:glyph, 0, 17, 1, [{3, {:modifier, 0, 0, [], []}}, {0, :empty}]}]}
    canonical = {:ithkuil_word, 1, [{:glyph, 0, 17, 1, [{3, {:modifier, 0, 0, [], []}}]}]}

    assert {:error, {:invalid_structure, :not_canonical}} = Ithkuil.validate(loose)
    assert {:ok, ^canonical} = Ithkuil.canonicalize(loose)
    assert {:ok, ^canonical} = Ithkuil.validate(canonical)
  end

  test "empty word round-trips through every projection" do
    empty = {:ithkuil_word, 1, []}
    assert {:ok, "8606843649"} = Ithkuil.to_integer_string(empty)
    assert {:ok, ^empty} = Ithkuil.from_integer_string("8606843649")

    assert {:ok, model} = Ithkuil.to_scene(empty)
    assert model.nodes == []

    svg = SVG.render(model, :exploded)
    assert {:ok, ["ithkuil-word", 1, []]} = SVG.extract_coordinate(svg)
  end
end
