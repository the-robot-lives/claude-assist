"""Romanization profile core-v1: conformance vectors + targeted refusals.

Normative: ../../ROMANIZATION.md; ../../conformance/latin_to_coordinate.jsonl
is the arbiter.  Every vector is driven in both directions where defined
(SDK-INTERFACE.md section 5).

The decomposition tests carry literal combining marks; each guards itself
with a ``unicodedata.normalize`` assertion so a source-encoding round trip
that recomposes them fails loudly instead of silently weakening the test.
"""

from __future__ import annotations

import json
import unicodedata
from pathlib import Path

import pytest

from ithkuil import coord, from_latin, romanization, to_latin

CONFORMANCE = Path(__file__).resolve().parents[2] / "conformance"


def load_vectors():
    rows = []
    for line in (CONFORMANCE / "latin_to_coordinate.jsonl").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    return rows


VECTORS = load_vectors()
ACCEPTED = [r for r in VECTORS if "coordinate" in r]
REJECTED = [r for r in VECTORS if "error" in r]


def test_vector_partition_is_total():
    assert VECTORS, "conformance file missing or empty"
    assert len(ACCEPTED) + len(REJECTED) == len(VECTORS)
    assert ACCEPTED and REJECTED


# --------------------------------------------------------------------------
# Golden vectors, both directions.
# --------------------------------------------------------------------------


@pytest.mark.parametrize("row", ACCEPTED, ids=lambda r: r["canonical"])
def test_accepted_vector(row):
    # from_latin(latin) == coordinate
    word = from_latin(row["latin"])
    assert coord.word_to_wire(word) == row["coordinate"]

    # to_latin(coordinate) == canonical (wire input canonicalized on entry)
    assert to_latin(row["coordinate"]) == row["canonical"]
    assert to_latin(word) == row["canonical"]

    # round-trip law: from_latin(to_latin(c)) == c
    assert from_latin(row["canonical"]) == word

    # canonical spelling is trimmed, lowercase, NFC
    canonical = row["canonical"]
    assert canonical == canonical.strip() == canonical.lower()
    assert canonical == unicodedata.normalize("NFC", canonical)


@pytest.mark.parametrize("row", REJECTED, ids=lambda r: repr(r["latin"]))
def test_rejected_vector(row):
    with pytest.raises(coord.IthkuilError) as e:
        from_latin(row["latin"])
    assert e.value.code == row["error"], f"expected {row['error']}, got {e.value.code}: {e.value}"
    assert str(e.value).startswith(row["error"] + ":")


# --------------------------------------------------------------------------
# Preprocessing (ROMANIZATION.md section 1): trim -> NFC -> lowercase.
# --------------------------------------------------------------------------


def test_preprocessing_accepts_decomposed_input():
    # "aks<caron>ale<diaeresis>i": s + U+030C and e + U+0308 (decomposed)
    decomposed = "akšalëi"
    # precomposed s-caron U+0161 and e-diaeresis U+00EB
    precomposed = "akšalëi"
    assert unicodedata.normalize("NFC", decomposed) == precomposed
    word = from_latin(decomposed)
    assert to_latin(word) == precomposed  # canonical spelling is precomposed
    assert word == from_latin(precomposed)


def test_uppercase_and_padding_are_preprocessed():
    assert from_latin("  Alala ") == from_latin("alala")
    assert to_latin(from_latin("  Alala ")) == "alala"


def test_decomposed_stress_mark_still_rejected():
    # a + U+0301 combining acute composes to U+00E1 under NFC -> Slot X stress
    with pytest.raises(coord.IthkuilError) as e:
        from_latin("álala")
    assert e.value.code == "unsupported"


def test_from_latin_requires_a_string():
    with pytest.raises(coord.IthkuilError) as e:
        from_latin(12)
    assert e.value.code == "invalid_structure"


# --------------------------------------------------------------------------
# Inventories and tables (ROMANIZATION.md sections 2, 4, 5).
# --------------------------------------------------------------------------


def test_inventories_are_nfc_and_exactly_sized():
    assert len(romanization.ROOT_CONSONANTS) == 27
    assert len(set(romanization.ROOT_CONSONANTS)) == 27
    assert len(romanization.VOWELS) == 9
    assert len(romanization.STRESS_VOWELS) == 10
    assert len(romanization.VC) == 9
    for ch in romanization.ROOT_CONSONANTS + romanization.VOWELS + romanization.VC:
        assert ch == unicodedata.normalize("NFC", ch)
    assert romanization.MAX_ROOT_CODE == 551880


def test_root_inventory_normative_order():
    # ROMANIZATION.md section 2.3: digit value = 1-based position.
    expected = (
        "p", "b", "t", "d", "k", "g", "f", "v", "ţ",
        "ḑ", "s", "z", "c", "ẓ", "š", "ž", "č", "j",
        "ç", "x", "ļ", "l", "r", "ř", "m", "n", "ň",
    )
    assert romanization.ROOT_CONSONANTS == expected


def test_bijective_base27_worked_examples():
    # ROMANIZATION.md section 5: p=1, n-caron=27, pp=28, ks-caron=150, ks-caron-t=4053
    cases = (("p", 1), ("ň", 27), ("pp", 28), ("kš", 150), ("kšt", 4053))
    for cluster, code in cases:
        latin = "a" + cluster + "ala"
        word = from_latin(latin)
        assert word.glyphs[0].base == code, f"root code mismatch for {cluster!r}"
        assert to_latin(word) == latin


# --------------------------------------------------------------------------
# to_latin shape gate (ROMANIZATION.md section 7).
# --------------------------------------------------------------------------


def _formative(base=22, stem=1, spec=0, fn_ver=0, perspective=0, case_index=0, cc=0):
    return [
        "ithkuil-word",
        1,
        [
            [
                "glyph",
                cc,
                base,
                stem,
                [
                    [0, ["modifier", spec, fn_ver, [], []]],
                    [1, ["modifier", perspective, 0, [], []]],
                    [2, ["modifier", case_index, 0, [], []]],
                ],
            ]
        ],
    ]


@pytest.mark.parametrize(
    "wire",
    [
        ["ithkuil-word", 1, []],  # zero glyphs
        ["ithkuil-word", 2, _formative()[2]],  # wrong schema version
        _formative()[:2] + [_formative()[2] * 2],  # two glyphs
        _formative(cc=1),  # non-formative character class
        _formative(base=0),  # root code 0
        _formative(base=551881),  # decode would exceed four consonants
        _formative(case_index=9),  # case index out of range
        # perspective modifier must have orientation 0
        ["ithkuil-word", 1, [["glyph", 0, 22, 1, [
            [0, ["modifier", 0, 0, [], []]],
            [1, ["modifier", 0, 1, [], []]],
            [2, ["modifier", 0, 0, [], []]]]]]],
        # wrong socket inventory (0,1,3 instead of 0,1,2)
        ["ithkuil-word", 1, [["glyph", 0, 22, 1, [
            [0, ["modifier", 0, 0, [], []]],
            [1, ["modifier", 0, 0, [], []]],
            [3, ["modifier", 0, 0, [], []]]]]]],
        # missing socket
        ["ithkuil-word", 1, [["glyph", 0, 22, 1, [
            [0, ["modifier", 0, 0, [], []]],
            [1, ["modifier", 0, 0, [], []]]]]]],
        # diacritics present
        ["ithkuil-word", 1, [["glyph", 0, 22, 1, [
            [0, ["modifier", 0, 0, [1], []]],
            [1, ["modifier", 0, 0, [], []]],
            [2, ["modifier", 0, 0, [], []]]]]]],
        # child sockets present
        ["ithkuil-word", 1, [["glyph", 0, 22, 1, [
            [0, ["modifier", 0, 0, [], [[0, ["modifier", 0, 0, [], []]]]]],
            [1, ["modifier", 0, 0, [], []]],
            [2, ["modifier", 0, 0, [], []]]]]]],
    ],
    ids=[
        "zero-glyphs", "version-2", "two-glyphs", "class-1", "base-0",
        "base-551881", "case-9", "perspective-orientation", "socket-3",
        "missing-socket", "diacritics", "child-sockets",
    ],
)
def test_to_latin_rejects_out_of_profile_shapes(wire):
    with pytest.raises(coord.IthkuilError) as e:
        to_latin(wire)
    assert e.value.code == "unsupported"


def test_to_latin_canonicalizes_wire_input_first():
    # Unsorted sockets are repaired at the wire boundary before the shape check.
    wire = [
        "ithkuil-word",
        1,
        [
            [
                "glyph",
                0,
                22,
                1,
                [
                    [2, ["modifier", 0, 0, [], []]],
                    [0, ["modifier", 0, 0, [], []]],
                    [1, ["modifier", 0, 0, [], []]],
                ],
            ]
        ],
    ]
    assert to_latin(wire) == "alala"
