"""Conformance-vector regeneration helper (opt-in; skipped by default).

Once an executable environment exists, run:

    ITHKUIL_EMIT_VECTORS=1 pytest tests/test_vector_gen.py -q

to have the REFERENCE codec emit expanded vectors for the PRODUCTION codec
to verify (never the same implementation on both sides of a vector --
conformance/README.md).  Outputs, under ../conformance/:

* ``coordinate_to_integer.expanded.jsonl`` -- generated word-level
  coordinate <-> bytes <-> integer rows (same shape as the seed file).
* ``scene_graph.jsonl`` -- coordinate -> render-model rows
  ``{"coordinate": ..., "model": ...}``; the Elixir scene compiler and
  web/src/scene.js must reproduce every row (missing JS object keys compare
  equal to null).

The seed files (codec_units.jsonl, coordinate_to_integer.jsonl,
invalid_inputs.jsonl) were computed by hand and are never overwritten.
"""

from __future__ import annotations

import json
import os
import random
from pathlib import Path

import pytest

from genwords import random_word
from ithkuil import codec, coord, scene

CONFORMANCE = Path(__file__).resolve().parents[2] / "conformance"

GENERATOR_SEED = 20260717
COORDINATE_ROWS = 64
SCENE_ROWS = 16


@pytest.mark.skipif(
    os.environ.get("ITHKUIL_EMIT_VECTORS") != "1",
    reason="vector regeneration is opt-in: set ITHKUIL_EMIT_VECTORS=1 once an "
    "executable environment exists",
)
def test_emit_expanded_vectors():
    rnd = random.Random(GENERATOR_SEED)

    rows = []
    for _ in range(COORDINATE_ROWS):
        word = random_word(rnd)
        data = codec.word_to_bytes(word)
        integer = codec.rank(data)
        # self-check before publishing anything
        assert codec.from_integer(integer) == word
        rows.append(
            {
                "coordinate": coord.word_to_wire(word),
                "bytes": data.hex(),
                "integer": str(integer),
            }
        )

    out = CONFORMANCE / "coordinate_to_integer.expanded.jsonl"
    out.write_text(
        "".join(json.dumps(r, separators=(",", ":")) + "\n" for r in rows),
        encoding="utf-8",
    )

    scene_rows = []
    for row in rows[:SCENE_ROWS]:
        model = scene.compile_scene(row["coordinate"], integer=row["integer"])
        scene_rows.append({"coordinate": row["coordinate"], "model": model})

    scene_out = CONFORMANCE / "scene_graph.jsonl"
    scene_out.write_text(
        "".join(json.dumps(r, separators=(",", ":")) + "\n" for r in scene_rows),
        encoding="utf-8",
    )

    assert out.exists() and scene_out.exists()
