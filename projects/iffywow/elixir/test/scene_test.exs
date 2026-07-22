defmodule Ithkuil.SceneTest do
  @moduledoc """
  Scene-compiler snapshot: stable node IDs and structure must match
  ../../web/src/scene.js node-for-node.
  """
  use ExUnit.Case, async: true

  alias Ithkuil.SVG

  @coordinate ["ithkuil-word", 1, [["glyph", 0, 17, 1, [[1, ["modifier", 6, 2, [3], []]]]]]]

  test "snapshot: node ids for glyph 0 / socket 1 / one diacritic" do
    assert {:ok, model} = Ithkuil.to_scene(@coordinate)

    assert Enum.map(model.nodes, & &1.id) ==
             ["g0", "g0.s1.link", "g0.s1.marker", "g0.s1.mod", "g0.s1.mod.d0"]

    assert Enum.map(model.nodes, & &1.kind) ==
             ["base", "connector", "socket-marker", "modifier", "diacritic"]

    assert Enum.map(model.nodes, &Map.get(&1, :parent_id)) ==
             [nil, "g0", "g0", "g0", "g0.s1.mod"]

    assert model.schema == "ithkuil-coordinate/1"
    assert model.coordinate == @coordinate
    assert is_binary(model.integer)
  end

  test "snapshot: placements follow the fixed-socket exploded geometry" do
    assert {:ok, model} = Ithkuil.to_scene(@coordinate)
    by_id = Map.new(model.nodes, &{&1.id, &1})

    base = by_id["g0"]
    # glyph orientation 1 -> 90 degrees, both projections
    assert base.compact.rotate == 90.0
    assert base.exploded.rotate == 90.0
    assert base.compact.translate == [0.0, 0.0]

    mod = by_id["g0.s1.mod"]
    # modifier orientation 2 -> 180, plus 90 frame -> 270
    assert mod.compact.rotate == 270.0
    assert mod.compact.scale == 0.5
    assert mod.exploded.scale == 1.4

    # socket 1 ("upper_right", -45deg) rotated by the 90deg frame -> +45deg:
    # compact anchor at ANCHOR_R=46 -> (32.5, 32.5); exploded orbit at
    # ORBIT_R=118 -> (83.4, 83.4) after 0.1 rounding.
    assert mod.compact.translate == [32.5, 32.5]
    assert mod.exploded.translate == [83.4, 83.4]

    marker = by_id["g0.s1.marker"]
    assert marker.socket.id == 1
    assert marker.socket.name == "upper_right"
    assert marker.socket.occupied == true
    assert marker.socket.anchor == [32.5, 32.5]
    assert marker.socket.orbit_center == [83.4, 83.4]
    assert marker.compact.visible == false
    assert marker.exploded.visible == true

    diacritic = by_id["g0.s1.mod.d0"]
    assert diacritic.parent_id == "g0.s1.mod"
    # diacritic slot 0: -90 + 270 (modDeg) = 180deg from the modifier center
    assert diacritic.compact.translate == [14.5, 32.5]
    assert diacritic.exploded.translate == [47.4, 83.4]
  end

  test "empty word yields the default view box and no nodes" do
    assert {:ok, model} = Ithkuil.to_scene(["ithkuil-word", 1, []])
    assert model.nodes == []
    assert model.view_box == [-60, -60, 120, 120]
  end

  test "rendered SVG carries schema + integer attributes and per-kind stroke attrs" do
    assert {:ok, model} = Ithkuil.to_scene(@coordinate)

    compact = SVG.render(model, :compact)
    assert compact =~ ~s(data-ithkuil-schema="ithkuil-coordinate/1")
    assert compact =~ ~s(data-ithkuil-integer=")
    assert compact =~ ~s(<metadata id="ithkuil-coordinate">)
    # connectors/markers are exploded-only
    refute compact =~ ~s(data-node-id="g0.s1.link")

    exploded = SVG.render(model, :exploded)
    assert exploded =~ ~s(data-node-id="g0.s1.link")
    assert exploded =~ ~s(stroke-dasharray="4 3")

    assert_raise ArgumentError, fn -> SVG.render(model, :sideways) end
  end
end
