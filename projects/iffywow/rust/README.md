# ithkuil (Rust core SDK)

Rust implementation of the iffywow New Ithkuil codec — **core conversions
only** (no scene/SVG/rendering). Implements interface v1 / schema v1 /
codec-v1 / romanization profile core-v1.

Normative documents: [`../SDK-INTERFACE.md`](../SDK-INTERFACE.md),
[`../CODEC.md`](../CODEC.md), [`../ROMANIZATION.md`](../ROMANIZATION.md);
the golden vectors in [`../conformance/`](../conformance/) are the arbiter.

## API

All canonical names re-exported at the crate root (`ithkuil::...`).

| Operation | Signature |
|---|---|
| `from_latin` | `&str -> Result<Word>` |
| `to_latin` | `&Word -> Result<String>` |
| `to_integer` | `&Word -> Result<BigUint>` |
| `from_integer` | `&BigUint -> Result<Word>` |
| `to_integer_string` | `&Word -> Result<String>` |
| `from_integer_string` | `&str -> Result<Word>` |
| `to_bytes` | `&Word -> Result<Vec<u8>>` |
| `from_bytes` | `&[u8] -> Result<Word>` |
| `to_wire` | `&Word -> serde_json::Value` |
| `from_wire` | `&serde_json::Value -> Result<Word>` |
| `to_wire_json` | `&Word -> String` |
| `from_wire_json` | `&str -> Result<Word>` |
| `validate` | `&Word -> Result<()>` |
| `canonicalize` | `&Word -> Result<Word>` |

Types: `Word`, `Glyph`, `Socket`, `Modifier` (`ithkuil::coord`), `Error`
with `code() -> &'static str` (`ithkuil::error`), plus the term-level codec
(`ithkuil::codec::{Term, serialize_term, deserialize_term, rank, unrank}`).

Notes:

- Because struct fields are public, a hand-built `Word` may be
  non-canonical; the `to_*` projections therefore validate first and return
  `Result` (use `canonicalize` to repair socket order). `to_wire` /
  `to_wire_json` are pure structural projections.
- Open enum ids are `u64` (`version` is `u32`). The byte codec itself is
  arbitrary-precision; serialized input carrying a field value outside the
  representable range is rejected with `invalid_structure`, never truncated.
- Romanization preprocessing approximates NFC with a targeted composition
  table over the profile alphabet only (see `src/romanization.rs`);
  out-of-alphabet input is rejected `unsupported` either way.

## Tests

```sh
cd rust
cargo test
```

- `tests/conformance.rs` — drives every vector in
  `../conformance/{codec_units,coordinate_to_integer,invalid_inputs,latin_to_coordinate}.jsonl`,
  both directions where defined.
- `tests/roundtrip.rs` — ~300 seeded-random words (LCG, no rand crate)
  asserting all SDK-INTERFACE §5 laws, plus wire-leniency and romanization
  round-trip properties.

## Verification status

Authored without execution (no cargo available in the authoring
environment); the suite above is the acceptance gate — run `cargo test`
before relying on this crate.
