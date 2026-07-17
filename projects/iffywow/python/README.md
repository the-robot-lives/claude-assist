# ithkuil — Python reference codec (iffywow)

The small, easy-to-inspect **mathematical reference and independent test
oracle** for the iffywow New Ithkuil coordinate SDK. It mirrors the Elixir
production codec's API and must agree with it on every vector in
`../conformance/*.jsonl` and with `../web/src/scene.js` node-for-node.

**This package is never in the live render path.** Its jobs are: (1) be
trivially auditable against `../CODEC.md`, (2) catch the production codec
lying, (3) generate expanded conformance vectors for the production codec to
verify (never the same implementation on both sides of a vector).

Stdlib only (`json`, `dataclasses`, `math`, `unicodedata`,
`xml.etree.ElementTree`). The sole dev dependency is `pytest`.

## Layout

| Module | Owns |
|---|---|
| `ithkuil/coord.py` | Frozen dataclasses `Word/Glyph/Socket/Modifier`, validation, canonicalization (sockets sorted ascending, duplicates rejected, empty sockets omitted), JSON tagged-array wire conversion |
| `ithkuil/codec.py` | codec-v1: minimal-LEB128 varints, term algebra ser/de (tags `0x00–0x03`, `0x04` rejected), word↔term mapping, ranking `E = S_m + V256(B)`, strict decode (leading zeros preserved, no trailing bytes), decimal-string boundary |
| `ithkuil/scene.py` | Deterministic scene compiler + seed geometry registry, ported from `web/src/{scene,registry,util}.js` |
| `ithkuil/svg.py` | `render(model, mode)` / `extract_coordinate(svg_text)` matching `web/src/metadata.js` byte-for-byte |
| `ithkuil/romanization.py` | Romanization profile core-v1 (`../ROMANIZATION.md`, normative): `Vv Cr Vr Ca Vc` formatives, closed tables, bijective base-27 roots; everything else raises `unsupported` instead of guessing |
| `ithkuil/__init__.py` | Public API mirroring Elixir `Ithkuil` (SDK-INTERFACE.md §2) |

## API

Full contract: `../SDK-INTERFACE.md` §2 (operations), §3 (error codes).

```python
import ithkuil

word = ithkuil.from_latin("alala")               # -> Word (romanization profile core-v1)
text = ithkuil.to_latin(word)                    # -> "alala" (canonical spelling: lowercase NFC)

n = ithkuil.to_integer(word)                     # -> int (arbitrary precision)
word2 = ithkuil.from_integer(n)                  # -> Word; word2 == word, exact

s = ithkuil.to_integer_string(word)              # -> unsigned decimal string
word3 = ithkuil.from_integer_string(s)           # the ONLY cross-boundary integer form

data = ithkuil.to_bytes(word)                    # -> bytes, canonical codec-v1 ser(word)
word4 = ithkuil.from_bytes(data)                 # strict: minimal varints, sorted sockets,
                                                 #         no trailing bytes

wire = ithkuil.to_wire(word)                     # -> canonical tagged arrays (lists/ints)
word5 = ithkuil.from_wire(wire)                  # LENIENT: sorts sockets, drops [id, null];
                                                 #          duplicates still error
text = ithkuil.to_wire_json(word)                # -> canonical wire JSON text
word6 = ithkuil.from_wire_json(text)             # lenient, same rules as from_wire

ithkuil.validate(word)                           # structural check of a native Word
ithkuil.canonicalize(wire)                       # lenient repair (sort, drop empties) + validate

model = ithkuil.to_scene(word, integer=s)        # {schema, latinized, integer,
                                                 #  coordinate, viewBox, nodes[]}
svg_text = ithkuil.svg.render(model, "exploded")
ithkuil.svg.extract_coordinate(svg_text)         # == ithkuil.word_to_wire(word)
```

Accepted coordinate inputs everywhere: a `Word`, a wire array
(`["ithkuil-word", 1, [...]]`), or its JSON text. `[id, null]` empty sockets
are accepted on input and canonicalized away. Strictness boundary
(SDK-INTERFACE.md): byte/integer inputs are STRICT; wire/JSON inputs are
lenient but canonicalizing. Invalid input raises `ithkuil.IthkuilError` (a
`ValueError`) whose message starts with a stable code from the
SDK-INTERFACE.md §3 registry (`nonminimal_varint`, `reserved_tag`,
`trailing_bytes`, `truncated`, `invalid_version`, `invalid_orientation`,
`invalid_socket_id`, `duplicate_socket`, `unsorted_sockets`,
`invalid_natural_number`, `invalid_structure`, `unsupported`, ...) matching
`conformance/invalid_inputs.jsonl` and `latin_to_coordinate.jsonl`.

## Running the tests

```bash
cd python
python -m venv .venv && . .venv/bin/activate
pip install -e ".[dev]"        # or just: pip install pytest
pytest                          # conformance + property + scene/svg tests
```

(`conftest.py` puts the package on `sys.path`, so a bare `pytest` from
`python/` works without installation.)

Regenerating expanded conformance vectors (opt-in; writes into
`../conformance/`):

```bash
ITHKUIL_EMIT_VECTORS=1 pytest tests/test_vector_gen.py -q
```

## Verification status

**This code was written without an executable Python environment** (authored
via file tooling only; neither `python` nor `pytest` has been run on it yet).
What has been verified by hand:

- Every row of `conformance/codec_units.jsonl` and
  `coordinate_to_integer.jsonl` recomputed manually against CODEC.md
  (varints, tag bytes, `S_m` values, base-256 values, final integers) —
  the implementation was written to those recomputations.
- The scene compiler was transcribed expression-by-expression from
  `web/src/scene.js` / `registry.js` / `util.js`, preserving arithmetic
  shape, operator associativity, and `rand()` call order.

First action once an interpreter is available: `pytest` — the suite is the
actual verification. Treat any failure as a bug in this package until proven
otherwise.

## JS-parity notes (the sharp edges, and how they are handled)

- **`Math.imul`**: returns the *signed* 32-bit low word; `util.js` always
  reapplies `>>> 0`, so unsigned semantics hold. Python:
  `((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF`.
- **`Math.round`**: rounds half-way cases toward +∞ (`Math.round(-2.5) === -2`)
  — `floor(x + 0.5)` semantics, *not* Python's banker's `round()`.
  `scene.js_round` implements "closest integer, ties toward +∞" via an exact
  `x - floor(x)` comparison, which also matches JS on the pathological
  double just below 0.5 where literal `floor(x + 0.5)` would misround.
- **Number formatting**: JS prints `40`, Python prints `40.0`. `r1` and the
  scale rounding normalize integral results (and `-0`) to `int`; non-integral
  doubles use the shortest round-trip repr, which CPython and JS engines
  share. All numbers embedded in strings go through `scene.js_num`.
- **Metadata JSON**: `json.dumps(..., separators=(",", ":"),
  ensure_ascii=False)` with fixed key order `schema, latinized, integer,
  mode, coordinate`, then `&` and `<` rewritten as JSON unicode escapes
  (backslash + `u0026` / `u003c`) — byte-identical to `JSON.stringify`
  plus the JS replaces.

## Known risks

1. **Unexecuted code.** See verification status above. Most likely failure
   classes are typos and import-order issues, which the first `pytest` run
   will surface immediately.
2. **libm trig parity.** `sin`/`cos` are not required to be correctly
   rounded in either language. CPython (platform libm) and V8/SpiderMonkey
   (fdlibm) could differ by 1 ulp on some argument, which could flip an
   `r1` result sitting exactly on a 0.05 boundary and change one decimal in
   a path string / placement. No such case is known; the
   `scene_graph.jsonl` vectors are the tripwire. If one ever fires, the fix
   is a shared correctly-rounded trig table in `spec/`, not per-runtime
   fudging.
3. **`hash32` inputs ≥ 2⁵³.** JS coerces through doubles, Python doesn't;
   registry seeds (`0x10000 + id` etc.) diverge for astronomically large
   enum IDs. Masked to 32 bits here, which matches JS exactly for all
   `|n| < 2⁵³`.
4. **Deep recursion.** Term (de)serialization and scene emission recurse per
   nesting level; CPython's default recursion limit (~1000) bounds decodable
   nesting depth. Acceptable for a reference codec; the official script
   needs finite shallow depth anyway.
5. **Romanization coverage is a deliberate sliver.** Profile core-v1 only
   (`../ROMANIZATION.md`): unconcatenated `Vv Cr Vr Ca Vc` formatives with
   closed slot tables and a 27-consonant bijective base-27 root inventory.
   Full slot I–IX morphology is registry-first and lands with `spec/*.yaml`
   as a new profile version; everything else raises `unsupported: ...`
   rather than minting enum IDs that could never be reassigned.
