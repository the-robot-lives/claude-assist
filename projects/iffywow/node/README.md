# @noizu/ithkuil

New Ithkuil codec-v1 core SDK for Node — **conversions only**, zero runtime
dependencies (Node ≥ 18, ESM). Implements SDK-INTERFACE v1: canonical
coordinate tuples, the codec-v1 byte/integer encoding, the JSON wire form,
and romanization profile core-v1.

Normative documents (this package must agree with all of them, and with every
vector in `../conformance/*.jsonl`):

- `../SDK-INTERFACE.md` — the language-agnostic contract (operations, laws, error codes)
- `../CODEC.md` — term algebra, byte serialization, integer ranking
- `../ROMANIZATION.md` — romanization profile core-v1

## API

```js
import {
  fromLatin, toLatin,                       // Latin  <-> Coord   (profile core-v1)
  toInteger, fromInteger,                   // Coord  <-> bigint  (codec-v1 ranking)
  toIntegerString, fromIntegerString,       // Coord  <-> unsigned decimal string
  toBytes, fromBytes,                       // Coord  <-> Uint8Array (canonical ser)
  toWire, fromWire,                         // Coord  <-> tagged arrays
  toWireJson, fromWireJson,                 // Coord  <-> wire JSON text
  validate, canonicalize,                   // native value -> canonical Coord
  IthkuilError,                             // .code = stable machine-readable code
} from "@noizu/ithkuil";

const c = fromLatin("alala");
toIntegerString(c);      // "…" — decimal string, the only cross-boundary integer form
toLatin(fromInteger(toInteger(c))) === "alala";
```

The canonical `Coord` is a deep-frozen plain object:

```js
{ version, glyphs: [{ characterClass, base, orientation, sockets: [{ id, modifier }] }] }
// modifier = { shape, orientation, diacritics: [nat], sockets: [{ id, modifier }] }
```

Sockets are sorted strictly ascending by `id`; **empty sockets are omitted**
(a canonical socket always carries a modifier).

### Strictness boundary (settled by SDK-INTERFACE)

- **Strict** — byte and integer inputs (`fromBytes`, `fromInteger`,
  `fromIntegerString`): one meaning, one representation. Minimal varints,
  sorted sockets, no trailing bytes, no `[id, null]` empties.
- **Lenient but canonicalizing** — wire/JSON and language-native inputs
  (`fromWire`, `fromWireJson`, `canonicalize`, and the coord arguments of the
  `to*` projections): unsorted sockets are sorted, `[id, null]` /
  `modifier: null` empties are dropped. Duplicate socket ids are **always**
  an error (`duplicate_socket`), never repaired.

### Integer policy: BigInt in, decimal strings at boundaries

All ranking arithmetic is `BigInt` end to end. `toInteger` returns a
`BigInt`; `fromInteger` accepts a `BigInt` (or a safe non-negative `Number`).
Crossing any language/JSON boundary, use `toIntegerString` /
`fromIntegerString` — unsigned decimal strings are the only sanctioned
cross-boundary integer form (JSON `BigInt` is not a thing).

Errors are `IthkuilError extends Error` with a stable `.code` from the
SDK-INTERFACE §3 registry (`unsupported`, `nonminimal_varint`,
`duplicate_socket`, …); `err.message` always begins with `"<code>: "`.

## Tests

```sh
npm test          # = node --test test/   (no install needed — zero deps)
```

- `test/conformance.test.js` drives **every** vector in
  `../conformance/{codec_units,coordinate_to_integer,invalid_inputs,latin_to_coordinate}.jsonl`,
  both directions where defined.
- `test/roundtrip.test.js` asserts every SDK-INTERFACE §5 law over ~300
  seeded random coordinates (deterministic LCG).

## Verification status

This package was **authored without execution** (written in an environment
with no Node runtime available). The conformance vectors are the arbiter:
run `npm test` before first use, and treat any failure there as a bug in
this package, not in the vectors.

## Relationship to `web/`

`web/` renders (`<ithkuil-word>` Lit element, scene graph, SVG); this package
**converts** (Latin ↔ Coord ↔ integer/bytes/wire). They share the wire
format and canonicalization semantics (`web/src/coordinate.js` and
`src/wire.js` accept and produce the same coordinates). `web/` may later
depend on this package for its coordinate handling; nothing here depends on
the DOM, Lit, or rendering.
