Code.require_file("support/conformance.exs", __DIR__)

defmodule Ithkuil.RoundTripTest do
  @moduledoc """
  Hand-rolled property-style round-trips over ~200 deterministic
  pseudo-random valid coordinates (seeded LCG, no dependencies):

      from_integer(to_integer(c))                       == {:ok, c}
      from_integer_string(to_integer_string(c))         == {:ok, c}
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

    # Canonical wire omits the empties: one meaning, one representation.
    assert Coord.to_wire(coord) ==
             ["ithkuil-word", 1, [["glyph", 0, 17, 1, [[1, ["modifier", 6, 2, [3], []]]]]]]
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
