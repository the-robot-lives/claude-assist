"""Golden-vector conformance tests -- every row of conformance/*.jsonl, both
directions.  These vectors, not shared code, keep the Elixir production codec
and this Python reference in sync (see ../../CODEC.md)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from ithkuil import codec, coord

CONFORMANCE = Path(__file__).resolve().parents[2] / "conformance"


def load_jsonl(name):
    rows = []
    for line in (CONFORMANCE / name).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    return rows


CODEC_UNITS = load_jsonl("codec_units.jsonl")
COORD_VECTORS = load_jsonl("coordinate_to_integer.jsonl")
INVALID = load_jsonl("invalid_inputs.jsonl")


# --------------------------------------------------------------------------
# codec_units.jsonl -- term-level ser/rank vectors (hand-computed, normative)
# --------------------------------------------------------------------------


@pytest.mark.parametrize("row", CODEC_UNITS, ids=lambda r: f"bytes-{r['bytes']}")
def test_codec_unit(row):
    term = codec.term_from_json(row["term"])
    data = bytes.fromhex(row["bytes"])
    integer = int(row["integer"])

    # serialize / deserialize
    assert codec.serialize_term(term) == data
    assert codec.deserialize_term(data) == term

    # rank / unrank
    assert codec.rank(data) == integer
    assert codec.unrank(integer) == data

    # JSON helper round-trip (keeps the vector format itself honest)
    assert codec.term_from_json(codec.term_to_json(term)) == term


# --------------------------------------------------------------------------
# coordinate_to_integer.jsonl -- word-level coordinate <-> bytes <-> integer
# --------------------------------------------------------------------------


@pytest.mark.parametrize("row", COORD_VECTORS, ids=lambda r: f"int-{r['integer']}")
def test_coordinate_vector(row):
    data = bytes.fromhex(row["bytes"])
    integer = int(row["integer"])
    word = coord.word_from_wire(row["coordinate"])

    # encode direction
    assert codec.word_to_bytes(word) == data
    assert codec.to_integer(word) == integer
    assert codec.to_integer_string(word) == row["integer"]

    # decode direction (leading zeros preserved, strict parse)
    assert codec.word_from_bytes(data) == word
    assert codec.from_integer(integer) == word
    assert codec.from_integer_string(row["integer"]) == word

    # the vector's coordinate is already canonical
    assert coord.word_to_wire(word) == row["coordinate"]

    # wire form accepted directly and as JSON text
    assert codec.to_integer(row["coordinate"]) == integer
    assert codec.to_integer(json.dumps(row["coordinate"])) == integer


# --------------------------------------------------------------------------
# invalid_inputs.jsonl -- inputs that MUST be rejected, by error class
# --------------------------------------------------------------------------


def _invalid_id(row):
    return f"{row['kind']}-{row['error']}"


@pytest.mark.parametrize("row", INVALID, ids=_invalid_id)
def test_invalid_input(row):
    kind = row["kind"]
    assert kind in ("integer_string", "bytes", "coordinate"), f"unknown vector kind {kind!r}"

    with pytest.raises(coord.IthkuilError) as exc_info:
        if kind == "integer_string":
            codec.from_integer_string(row["value"])
        elif kind == "bytes":
            codec.word_from_bytes(bytes.fromhex(row["value"]))
        else:  # coordinate
            coord.word_from_wire(row["value"])

    err = exc_info.value
    assert err.code == row["error"], f"expected {row['error']}, got {err.code}: {err}"
    # message starts with the machine-readable code
    assert str(err).startswith(row["error"] + ":")
