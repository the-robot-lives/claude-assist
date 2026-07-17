# iffywow codec-v1 — normative specification

This document is the byte-level contract between the Elixir production codec
and the Python reference codec. Both MUST agree with every rule here and with
every vector in `conformance/`. Changes require a schema-version bump; tag
bytes and published integer meanings are permanent.

## 1. Term algebra

A term `t` is one of:

| Tag byte | Term | Payload |
|---|---|---|
| `0x00` | `NAT n` | minimal unsigned LEB128 varint of `n` |
| `0x01` | `PAIR (x, y)` | `ser(x) ser(y)` |
| `0x02` | `LIST [e₀ … e_{k−1}]` | varint `k`, then `ser(e₀) … ser(e_{k−1})` |
| `0x03` | `BYTES b` | varint `len(b)`, then the raw bytes |
| `0x04` | reserved | reserved control value — never emitted in v1; decoders MUST reject |

`ser(t)` = tag byte followed by payload. Serialization is prefix-decodable:
no lookahead beyond the construct being read.

**Varint (unsigned LEB128):** little-endian 7-bit groups; high bit = continue.
Canonical encodings are minimal — a final `0x00` continuation group is
invalid (e.g. `0x80 0x00` for 0 MUST be rejected). Examples: `0 → 00`,
`127 → 7F`, `128 → 80 01`, `300 → AC 02`.

## 2. Word → term mapping (schema v1)

```text
word      := PAIR( NAT version, LIST glyphs )
glyph     := LIST[ NAT character_class, NAT base, NAT orientation, LIST sockets ]
socket    := PAIR( NAT socket_id, modifier )
modifier  := LIST[ NAT shape, NAT orientation, LIST diacritics(NAT), LIST sockets ]
```

Canonical-form requirements (encoders MUST produce, strict decoders MUST reject
violations):

1. All varints minimal.
2. `version ≥ 1`; in schema v1, `orientation ∈ 0..3`, `socket_id ∈ 0..7`.
3. Sockets sorted strictly ascending by `socket_id` (duplicates invalid).
4. **Empty sockets are omitted.** The wire form `[id, null]` is accepted on
   *input* at JSON boundaries but never appears in the canonical form or the
   byte encoding — one meaning, one representation. (Exploded rendering
   derives the full fixed socket inventory from the registry, not from the
   tuple.)
5. No trailing bytes after the root term.

JSON wire form (tagged arrays) maps 1:1:
`["ithkuil-word", v, glyphs]`, `["glyph", cc, base, o, sockets]`,
`[socket_id, modifier]`, `["modifier", shape, o, diacritics, sockets]`.
Tags are positional in the byte encoding; the strings exist only in JSON.

## 3. Integer ranking

Let `B = ser(word)` with byte length `m`, and let `V₂₅₆(B)` read `B` as a
big-endian base-256 integer. Then:

```text
S_m  = (256^m − 1) / 255          (= Σ_{j<m} 256^j; number of strings shorter than m)
E(t) = S_m + V₂₅₆(B)
```

Length intervals are disjoint (`S_m ≤ E < S_{m+1}`), so decoding recovers `m`
first (largest `m` with `S_m ≤ E`), then `B = E − S_m` as exactly `m` bytes
**preserving leading zeros**, then parses the term strictly. Every natural
number decodes to some byte string, but only canonical serializations of valid
words decode successfully — `from_integer/1` returns an error otherwise.

**Boundary rule:** the integer crosses every language/JSON boundary as an
unsigned decimal string (`to_integer_string` / `from_integer_string`).
Arbitrary-precision arithmetic internally is fine; JSON `BigInt` is not.

## 4. Worked example (normative)

Empty word `["ithkuil-word", 1, []]`:

```text
term  = PAIR(NAT 1, LIST [])
ser   = 01 | 00 01 | 02 00            → B = 01 00 01 02 00, m = 5
S_5   = (256^5 − 1)/255 = 4 311 810 305
V₂₅₆  = 0x0100010200      = 4 295 033 344
E     = 8 606 843 649
```

`from_integer_string("8606843649")` MUST return the empty word; both codecs
MUST reproduce every row of `conformance/codec_units.jsonl` and
`conformance/coordinate_to_integer.jsonl`.

## 5. Required API surface

Elixir `Ithkuil` (production) and Python `ithkuil` (reference) expose matching
functions: `from_latin`, `to_latin`, `to_integer`, `from_integer`,
`to_integer_string`, `from_integer_string`, `to_scene`, plus
`Ithkuil.SVG.render/extract_coordinate` (and Python `svg.render` /
`svg.extract_coordinate`). Laws:

```text
from_integer(to_integer(c))            == {:ok, c}
to_latin(from_latin(w))                == {:ok, canonicalize(w)}
extract_coordinate(render(to_scene(c))) == c
```

Scene compilation must be node-for-node deterministic and agree with
`web/src/scene.js` (same constants, same node IDs, same placements) so all
three runtimes draw the same word identically.
