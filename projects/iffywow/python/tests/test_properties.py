"""Seeded round-trip property tests over generated valid coordinates.

Acceptance laws (README.md / CODEC.md section 5)::

    from_integer(to_integer(c)) == c                                  # exact
    svg.extract_coordinate(svg.render(to_scene(c))) == wire(c)        # metadata
"""

from __future__ import annotations

import random

import pytest

from genwords import random_word
from ithkuil import codec, coord, scene, svg

SEED = 0xC0FFEE
CASES = 500


def test_integer_and_svg_round_trips():
    rnd = random.Random(SEED)
    for i in range(CASES):
        word = random_word(rnd)

        # integer round trip -- exact
        n = codec.to_integer(word)
        assert codec.from_integer(n) == word, f"integer round-trip failed at case {i}: {word!r}"

        # decimal-string boundary round trip
        s = codec.to_integer_string(word)
        assert s == str(n)
        assert codec.from_integer_string(s) == word, f"string round-trip failed at case {i}"

        # bytes round trip (leading zeros preserved by construction)
        data = codec.word_to_bytes(word)
        assert codec.word_from_bytes(data) == word
        assert codec.rank(data) == n
        assert codec.unrank(n) == data

        # scene -> SVG -> metadata extraction round trip, both modes
        model = scene.compile_scene(word, integer=s)
        mode = "exploded" if i % 2 else "compact"
        svg_text = svg.render(model, mode)
        assert svg.extract_coordinate(svg_text) == coord.word_to_wire(word), (
            f"svg round-trip failed at case {i} (mode={mode})"
        )


def test_wire_round_trip_is_canonical():
    rnd = random.Random(SEED + 1)
    for _ in range(100):
        word = random_word(rnd)
        wire = coord.word_to_wire(word)
        assert coord.word_from_wire(wire) == word
        # canonical form is a fixed point
        assert coord.canonical_wire(wire) == wire


def test_canonicalization_sorts_and_drops_empty_sockets():
    modifier = ["modifier", 6, 2, [3], []]
    wire = [
        "ithkuil-word",
        1,
        [["glyph", 0, 17, 1, [[3, modifier], [1, None], [0, modifier]]]],
    ]
    word = coord.word_from_wire(wire)
    canonical = coord.word_to_wire(word)
    # empty socket 1 omitted; occupied sockets sorted ascending
    assert canonical == [
        "ithkuil-word",
        1,
        [["glyph", 0, 17, 1, [[0, modifier], [3, modifier]]]],
    ]


def test_empty_word_normative_example():
    """CODEC.md section 4 worked example, kept alongside the property suite."""
    empty = coord.Word(1, ())
    assert codec.word_to_bytes(empty) == bytes.fromhex("0100010200")
    assert codec.to_integer(empty) == 8606843649
    assert codec.from_integer_string("8606843649") == empty


def test_from_integer_rejects_non_naturals():
    for bad in (-1, 1.5, "12", None, True):
        with pytest.raises(coord.IthkuilError) as e:
            codec.from_integer(bad)
        assert e.value.code == "invalid_natural_number"


def test_noncanonical_integers_fail_decode():
    # 0 -> empty byte string -> truncated (no tag byte)
    with pytest.raises(coord.IthkuilError) as e:
        codec.from_integer(0)
    assert e.value.code == "truncated"
    # 257 + 0x0400 -> bytes 04 00 -> reserved tag
    with pytest.raises(coord.IthkuilError) as e:
        codec.from_integer(257 + 0x0400)
    assert e.value.code == "reserved_tag"
