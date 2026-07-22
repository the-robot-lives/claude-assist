# ithkuil (Elixir) — iffywow production codec

Production Elixir SDK for the iffywow New Ithkuil coordinate scheme.
Normative contracts: `../CODEC.md` (byte-level codec-v1), `../README.md`
(architecture), `../conformance/*.jsonl` (golden vectors shared with the
Python reference codec).

**Zero dependencies** — pure stdlib Elixir. No Jason: JSON *text* never
crosses the public API; the tiny JSON needs (SVG metadata embedding /
extraction, conformance JSONL parsing) are hand-rolled in `Ithkuil.JSON`.

## API

Full contract: `../SDK-INTERFACE.md` §2 (operations), §3 (error codes).

```elixir
{:ok, coord}   = Ithkuil.from_latin("alala")          # romanization profile core-v1 (partial; see below)
{:ok, "alala"} = Ithkuil.to_latin(coord)              # canonical spelling (lowercase, NFC)

{:ok, n}       = Ithkuil.to_integer(coord)            # codec-v1 ranking (arbitrary precision)
{:ok, coord}   = Ithkuil.from_integer(n)              # strict: only canonical words decode
{:ok, s}       = Ithkuil.to_integer_string(coord)     # unsigned decimal string — the boundary form
{:ok, coord}   = Ithkuil.from_integer_string(s)

{:ok, bytes}   = Ithkuil.to_bytes(coord)              # canonical codec-v1 ser(word)
{:ok, coord}   = Ithkuil.from_bytes(bytes)            # strict: minimal varints, sorted sockets, no trailing bytes

{:ok, wire}    = Ithkuil.to_wire(coord)               # canonical tagged arrays (Elixir data)
{:ok, coord}   = Ithkuil.from_wire(wire)              # LENIENT: sorts sockets, drops [id, nil]; duplicates error
{:ok, json}    = Ithkuil.to_wire_json(coord)          # canonical wire-form JSON text
{:ok, coord}   = Ithkuil.from_wire_json(json)         # lenient, same rules as from_wire/1

{:ok, coord}   = Ithkuil.validate(coord)              # structural check; input must already be canonical
{:ok, coord}   = Ithkuil.canonicalize(loose)          # lenient repair (sort, drop empties) + validate

{:ok, model}   = Ithkuil.to_scene(coord)              # deterministic render model (node-for-node = web/src/scene.js)
svg            = Ithkuil.SVG.render(model, :compact)  # or :exploded
{:ok, wire}    = Ithkuil.SVG.extract_coordinate(svg)  # exact recovery from embedded metadata
{:ok, coord}   = Ithkuil.Coord.from_wire(wire)
```

Coordinate arguments accept the canonical tuple or the JSON tagged-array wire
form (as Elixir data) and are canonicalized on entry: sockets sorted
ascending, duplicates rejected, empty sockets omitted. Strictness boundary
(SDK-INTERFACE.md): byte/integer inputs are STRICT; wire/JSON inputs are
lenient but canonicalizing. Error tuples carry a code from the
SDK-INTERFACE.md §3 registry, e.g. `{:error, {:unsupported, detail}}`.

## Layout

```text
lib/ithkuil.ex               public API (from_latin ... to_scene)
lib/ithkuil/coord.ex         canonical tuple: types, validate/canonicalize, wire conversion
lib/ithkuil/codec.ex         codec-v1: LEB128 varints, term algebra ser/de, integer ranking
lib/ithkuil/scene.ex         scene compiler — faithful port of ../web/src/{scene,registry,util}.js
lib/ithkuil/svg.ex           SVG render + metadata extraction (../web/src/metadata.js twin)
lib/ithkuil/romanization.ex  Ithkuil IV romanization (partial, documented coverage)
lib/ithkuil/json.ex          minimal internal JSON encode/parse + JS-parity number formatting
test/                        conformance vectors, seeded round-trip properties, scene snapshots
```

## Tests

```bash
cd elixir
mix test
```

- `test/conformance_test.exs` asserts every row of `../conformance/codec_units.jsonl`,
  `coordinate_to_integer.jsonl`, `invalid_inputs.jsonl` and
  `latin_to_coordinate.jsonl` in both directions.
- `test/round_trip_test.exs` runs ~200 seeded pseudo-random coordinates through
  the integer, integer-string, bytes, wire, and wire-JSON round-trips
  (plus `validate`/`canonicalize` fixpoints) and the SVG-metadata round-trip.
- `test/scene_test.exs` snapshots stable node IDs
  (`g0`, `g0.s1.link`, `g0.s1.marker`, `g0.s1.mod`, `g0.s1.mod.d0`) and placements.
- `test/romanization_test.exs` covers the supported romanization subset and its
  refusal behavior.

## Romanization coverage (partial by design)

`Ithkuil.Romanization` is the origin of **romanization profile core-v1**
(`../ROMANIZATION.md`, normative): exactly the formative shape
`Vv Cr Vr Ca Vc` with closed tables for Vv (stem/version), Vr
(function/specification, EXS context), Ca (the four default single-consonant
forms), Vc (cases 1–9), and a 27-consonant root inventory read as a bijective
base-27 numeral. Everything else — Cc, affixes, VnCn, stress, concatenation —
returns `{:error, {:unsupported, detail}}` rather than guessing. The
morpheme→coordinate mapping is **provisional but frozen for core-v1**;
`../conformance/latin_to_coordinate.jsonl` is the arbiter.

## Verification status

Written without an executable environment (no `mix`, no shell): the code has
**not been compiled or run**. The conformance vectors, the CODEC.md worked
example, and the seeded property tests are the safety net — run `mix test`
before first use, and regenerate `../conformance/scene_graph.jsonl` from the
JS compiler to cross-check scene placements (libm `sin`/`cos` may differ from
JS engines in the last ulp; all rounding here mirrors JS `Math.round`
semantics exactly).
