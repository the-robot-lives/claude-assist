# iffywow SDK interface v1 — normative

The language-agnostic contract every core SDK implements. Companion documents:
`CODEC.md` (byte/integer encoding, normative), `ROMANIZATION.md` (romanization
profile core-v1, normative), `conformance/` (golden vectors, the arbiter).
The core SDK is *conversions only* — no scene graphs, no SVG, no rendering, no
frontend glue. (Elixir/Python additionally ship scene/SVG layers; those are
extensions, not part of this interface.)

## 1. Value domains

| Domain | Definition |
|---|---|
| `Coord` | Canonical word per CODEC.md §2 — validated, sockets strictly ascending, empty sockets omitted |
| `Latin` | Canonical romanization, Unicode NFC (profile core-v1; see ROMANIZATION.md) |
| `Integer` | Natural number, arbitrary precision (native bigint type per language) |
| `IntegerString` | Unsigned decimal string — the ONLY cross-boundary integer form |
| `Bytes` | Canonical codec-v1 serialization `ser(word)` |
| `Wire` | JSON tagged arrays `["ithkuil-word", v, …]` — structural and/or JSON-text form |

## 2. Operations

Canonical names below; each language maps them via §4. `from_X` constructs a
`Coord` from X (fallible); `to_X` projects a `Coord` to X (`to_latin` fallible
— coverage; the rest of the `to_*` family total on valid `Coord`s).

| Operation | Signature | Notes |
|---|---|---|
| `from_latin` | `Latin → Result<Coord>` | Rejects outside profile: error `unsupported` |
| `to_latin` | `Coord → Result<Latin>` | Canonical spelling, NFC |
| `to_integer` | `Coord → Integer` | `E(t)` per CODEC.md §3 |
| `from_integer` | `Integer → Result<Coord>` | Strict decode |
| `to_integer_string` | `Coord → IntegerString` | |
| `from_integer_string` | `IntegerString → Result<Coord>` | Rejects sign/empty/non-digits: `invalid_natural_number` |
| `to_bytes` | `Coord → Bytes` | Canonical `ser(word)` |
| `from_bytes` | `Bytes → Result<Coord>` | Strict: minimal varints, sorted sockets, no trailing bytes |
| `to_wire` | `Coord → Wire` | Canonical tagged arrays |
| `from_wire` | `Wire → Result<Coord>` | **Lenient-canonicalizing**: accepts unsorted sockets and `[id, null]` empties; sorts, drops empties; duplicates still error |
| `to_wire_json` / `from_wire_json` | `Coord ↔ JSON text` | Required in every language; structural `Wire` additionally where natural |
| `validate` | `data → Result<Coord>` | Structural check of a language-native coord value |
| `canonicalize` | `data → Result<Coord>` | Lenient repair (sort, drop empties) + validate |

Strictness boundary (settled): byte/integer inputs are STRICT (one meaning,
one representation); wire/JSON and language-native inputs are LENIENT but
canonicalizing. Duplicated sockets are always an error, never repaired.

## 3. Error model

Errors carry a stable machine-readable code from this registry (see
`conformance/invalid_inputs.jsonl`): `invalid_natural_number`,
`nonminimal_varint`, `reserved_tag`, `unknown_tag`, `truncated`,
`trailing_bytes`, `invalid_version`, `invalid_orientation`,
`invalid_socket_id`, `duplicate_socket`, `unsorted_sockets`,
`invalid_structure`, `unsupported`. Codes are permanent; add, never rename.

## 4. Per-language surface

| Canonical | Elixir `elixir/` | Python `python/` | Node `node/` | Rust `rust/` | Go `go/` |
|---|---|---|---|---|---|
| package | `Ithkuil` | `ithkuil` | `@noizu/ithkuil` | `ithkuil` crate | `ithkuil` pkg |
| `from_latin` | `from_latin/1` | `from_latin` | `fromLatin` | `from_latin` | `FromLatin` |
| `to_integer` | `to_integer/1` | `to_integer` | `toInteger` | `to_integer` | `ToInteger` |
| …and so on | snake_case | snake_case | camelCase | snake_case | PascalCase |
| Integer type | `integer()` | `int` | `BigInt` | `num_bigint::BigUint` | `*big.Int` |
| Errors | `{:error, {code, detail}}` | `IthkuilError(ValueError)` with `.code` | `IthkuilError extends Error` with `.code` | `enum Error` with `code()` | `*Error` with `Code`, `errors.Is` support |
| Fallible return | `{:ok, v} \| {:error, e}` | raise | throw | `Result<T, Error>` | `(T, error)` |

Every SDK is dependency-light: Elixir/Python/Node stdlib-only; Rust may use
`num-bigint` (+ optional `serde_json` for wire JSON); Go stdlib only
(`math/big`, `encoding/json`).

## 5. Laws (asserted by every test suite)

```text
from_integer(to_integer(c))              == c
from_integer_string(to_integer_string(c)) == c
from_bytes(to_bytes(c))                  == c
from_wire(to_wire(c))                    == c
from_latin(to_latin(c))                  == c           (for c in profile)
to_latin(from_latin(w))                  == canonicalize(w)
```

Cross-language: identical `Coord` ⇒ byte-identical `Bytes`, equal `Integer`,
equal canonical `Wire` JSON, identical `Latin`. `conformance/*.jsonl` is the
arbiter; every SDK's suite must drive every vector in `codec_units.jsonl`,
`coordinate_to_integer.jsonl`, `invalid_inputs.jsonl`, and
`latin_to_coordinate.jsonl`, both directions where defined.

## 6. Versioning

Interface v1 ⋅ schema v1 ⋅ codec-v1 ⋅ romanization profile core-v1. Breaking
any of §1–§5 requires bumping the corresponding version; published integer
meanings and error codes are permanent.
