# Conformance vectors

Golden vectors both codecs (Elixir production, Python reference) must pass.
Integers are unsigned decimal strings; `bytes` are lowercase hex of the
canonical codec-v1 serialization (see ../CODEC.md).

| File | Covers |
|---|---|
| `codec_units.jsonl` | Term-level ser/rank vectors (hand-computed, normative) |
| `coordinate_to_integer.jsonl` | Word-level coordinate ↔ bytes ↔ integer |
| `invalid_inputs.jsonl` | Inputs that MUST be rejected, with expected error class |
| `latin_to_coordinate.jsonl` | Romanization ↔ coordinate (profile core-v1, normative vectors; see ../ROMANIZATION.md) |
| `scene_graph.jsonl` | Coordinate → scene-graph vectors (generated once an executable environment is available; must match web/src/scene.js) |

Seed vectors were computed by hand; expand them mechanically (reference codec
generates, production codec verifies — never the same implementation for both
sides of a vector).
