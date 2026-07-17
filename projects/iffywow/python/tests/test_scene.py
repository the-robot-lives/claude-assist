"""Scene compiler + SVG renderer snapshot/structure tests.

Placement values that depend on libm trig are asserted structurally, not
numerically, to keep the suite meaningful without baking in tautologies;
cross-runtime numeric parity is pinned by conformance/scene_graph.jsonl once
generated (see test_vector_gen.py).
"""

from __future__ import annotations

import json

import pytest

from ithkuil import coord, scene, svg

SNAPSHOT_COORD = ["ithkuil-word", 1, [["glyph", 0, 17, 1, [[1, ["modifier", 6, 2, [3], []]]]]]]


def test_scene_snapshot_node_ids():
    model = scene.compile_scene(SNAPSHOT_COORD)
    ids = [n["id"] for n in model["nodes"]]
    assert ids == ["g0", "g0.s1.link", "g0.s1.marker", "g0.s1.mod", "g0.s1.mod.d0"]


def test_scene_snapshot_structure():
    model = scene.compile_scene(SNAPSHOT_COORD)

    assert model["schema"] == "ithkuil-coordinate/1"
    assert model["latinized"] is None
    assert model["integer"] is None
    assert model["coordinate"] == SNAPSHOT_COORD
    assert len(model["viewBox"]) == 4
    assert model["viewBox"][2] > 0 and model["viewBox"][3] > 0

    base, link, marker, mod, d0 = model["nodes"]

    kinds = [n["kind"] for n in model["nodes"]]
    assert kinds == ["base", "connector", "socket-marker", "modifier", "diacritic"]

    # base: first glyph at origin, orientation 1 -> 90 degrees, no parent
    assert "parentId" not in base
    assert base["compact"] == {"translate": [0, 0], "rotate": 90, "scale": 1, "visible": True}
    assert base["exploded"] == {"translate": [0, 0], "rotate": 90, "scale": 1, "visible": True}
    assert base["path"].startswith("M ")

    # connector + marker are exploded-only overlays parented to the glyph
    hidden = {"translate": [0, 0], "rotate": 0, "scale": 1, "visible": False}
    shown = {"translate": [0, 0], "rotate": 0, "scale": 1, "visible": True}
    for node in (link, marker):
        assert node["parentId"] == "g0"
        assert node["compact"] == hidden
        assert node["exploded"] == shown
    assert link["path"].startswith("M 0 0 L ")

    # socket annotation on the marker node
    sock = marker["socket"]
    assert sock["id"] == 1
    assert sock["name"] == "upper_right"
    assert sock["occupied"] is True
    assert len(sock["anchor"]) == 2 and len(sock["orbitCenter"]) == 2

    # modifier: one node, two projections; orientation 2 (180) + frame 90 = 270
    assert mod["parentId"] == "g0"
    assert mod["compact"]["rotate"] == 270
    assert mod["exploded"]["rotate"] == 270
    assert mod["compact"]["scale"] == 0.5  # COMPACT_MOD_SCALE * k, depth 0
    assert mod["exploded"]["scale"] == 1.4  # EXPLODED_MOD_SCALE * k, depth 0
    assert mod["compact"]["visible"] is True and mod["exploded"]["visible"] is True

    # diacritic: parented to the modifier node, rotation in fixed 45deg steps
    assert d0["parentId"] == "g0.s1.mod"
    assert d0["kind"] == "diacritic"
    assert d0["compact"]["rotate"] == d0["exploded"]["rotate"]
    assert d0["compact"]["rotate"] in {0, 45, 90, 135, 180, 225, 270, 315}
    assert d0["compact"]["rotate"] == scene.diacritic_rotation(3)


def test_empty_word_default_viewbox():
    model = scene.compile_scene(["ithkuil-word", 1, []])
    assert model["nodes"] == []
    assert model["viewBox"] == [-60, -60, 120, 120]


def test_registry_determinism_and_helpers():
    # identical inputs -> identical paths, across calls
    assert scene.base_path(17) == scene.base_path(17)
    assert scene.modifier_path(6) == scene.modifier_path(6)
    assert scene.base_path(17) != scene.base_path(18)

    # hash32 is a stable unsigned 32-bit value
    h = scene.hash32(0x10000 + 17)
    assert h == scene.hash32(0x10000 + 17)
    assert 0 <= h < 2**32

    # LCG first step is exact: (0*1664525 + 1013904223) / 2**32
    assert scene.rng(0)() == 1013904223 / 4294967296

    # JS Math.round semantics: ties toward +Infinity, in both signs
    assert scene.js_round(2.5) == 3
    assert scene.js_round(-2.5) == -2
    assert scene.js_round(-0.5) == 0
    assert scene.r1(0.25) == 0.3
    assert scene.r1(-0.25) == -0.2
    assert scene.r1(-0.03) == 0  # -0 normalized
    assert scene.r1(130) == 130 and isinstance(scene.r1(130), int)

    # fixed socket inventory
    assert scene.socket_by_id(1)["name"] == "upper_right"
    assert scene.orientation_degrees(3) == 270


def test_svg_document_shape_and_metadata():
    latin = 'a&b<c>"d'
    model = scene.compile_scene(SNAPSHOT_COORD, latinized=latin, integer="12345")
    out = svg.render(model, "exploded")

    assert out.startswith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="')
    assert out.endswith("</svg>\n")
    assert 'data-ithkuil-schema="ithkuil-coordinate/1"' in out
    assert 'data-ithkuil-integer="12345"' in out
    assert "<title>a&amp;b&lt;c&gt;&quot;d</title>" in out
    assert '<metadata id="ithkuil-coordinate">' in out
    # metadata JSON escapes & and < as \u escapes, never as XML entities
    assert "\\u0026" in out and "\\u003c" in out

    meta = svg.extract_metadata(out)
    assert meta["schema"] == "ithkuil-coordinate/1"
    assert meta["latinized"] == latin
    assert meta["integer"] == "12345"
    assert meta["mode"] == "exploded"
    assert meta["coordinate"] == SNAPSHOT_COORD
    assert svg.extract_coordinate(out) == SNAPSHOT_COORD

    # compact mode hides exploded-only overlay nodes
    compact = svg.render(model, "compact")
    assert 'data-kind="connector"' not in compact
    assert 'data-kind="connector"' in out

    # metadata key order is fixed: schema, latinized, integer, mode, coordinate
    meta_text = out.split('<metadata id="ithkuil-coordinate">', 1)[1].split("</metadata>", 1)[0]
    keys = list(json.loads(meta_text).keys())
    assert keys == ["schema", "latinized", "integer", "mode", "coordinate"]


def test_svg_unknown_mode_rejected():
    model = scene.compile_scene(["ithkuil-word", 1, []])
    with pytest.raises(ValueError, match="unknown mode: sideways"):
        svg.render(model, "sideways")


def test_extract_coordinate_degrades_to_none():
    assert svg.extract_coordinate("not svg at all") is None
    assert svg.extract_coordinate("<svg xmlns='http://www.w3.org/2000/svg'></svg>") is None
    assert (
        svg.extract_coordinate(
            "<svg xmlns='http://www.w3.org/2000/svg'>"
            "<metadata id='ithkuil-coordinate'>not json</metadata></svg>"
        )
        is None
    )


def test_scene_accepts_word_wire_and_json_text():
    word = coord.word_from_wire(SNAPSHOT_COORD)
    a = scene.compile_scene(word)
    b = scene.compile_scene(SNAPSHOT_COORD)
    c = scene.compile_scene(json.dumps(SNAPSHOT_COORD))
    assert a == b == c
