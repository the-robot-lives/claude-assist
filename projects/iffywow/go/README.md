# ithkuil (Go core SDK)

Go implementation of the iffywow New Ithkuil codec — conversions only
(SDK-INTERFACE.md v1, codec-v1, romanization profile core-v1). No scene
graph, no SVG, no rendering. Standard library only (`math/big`,
`encoding/json`).

Normative references live one directory up: `../SDK-INTERFACE.md`,
`../CODEC.md`, `../ROMANIZATION.md`, with `../conformance/*.jsonl` as the
arbiter.

## API

```go
import ithkuil "github.com/noizu/iffywow/go"

ithkuil.Validate(w Word) error                     // strict structural check
ithkuil.Canonicalize(w Word) (Word, error)         // lenient repair: sort sockets; duplicates error

ithkuil.ToBytes(w Word) []byte                     // canonical codec-v1 ser(word)
ithkuil.FromBytes(b []byte) (Word, error)          // strict decode
ithkuil.ToInteger(w Word) *big.Int                 // E(t) per CODEC.md §3
ithkuil.FromInteger(n *big.Int) (Word, error)      // strict decode
ithkuil.ToIntegerString(w Word) string             // unsigned decimal (boundary form)
ithkuil.FromIntegerString(s string) (Word, error)  // rejects sign/empty/non-digits

ithkuil.ToWire(w Word) []interface{}               // canonical tagged arrays
ithkuil.FromWire(v []interface{}) (Word, error)    // lenient-canonicalizing
ithkuil.ToWireJSON(w Word) ([]byte, error)         // canonical wire JSON text
ithkuil.FromWireJSON(b []byte) (Word, error)       // lenient-canonicalizing

ithkuil.FromLatin(s string) (Word, error)          // romanization profile core-v1
ithkuil.ToLatin(w Word) (string, error)            // canonical spelling
```

Errors are `*ithkuil.Error` values with a stable `Code` from the
SDK-INTERFACE.md §3 registry; match with `errors.Is` against the exported
sentinels (`ErrTruncated`, `ErrDuplicateSocket`, `ErrUnsupported`, ...).

Strictness boundary: byte/integer inputs are strict; wire/JSON and
language-native inputs are lenient but canonicalizing (sockets sorted,
`[id, null]` empties dropped). Duplicate sockets always error.

## Tests

```sh
cd go
go test ./...
```

`conformance_test.go` drives every vector in all four
`../conformance/*.jsonl` files in both directions; `roundtrip_test.go`
asserts the SDK-INTERFACE.md §5 laws over ~300 seeded-LCG generated words.

## Notes

- **Verification status:** this SDK was authored without executing the Go
  toolchain (no `go build`/`go test` run yet in this environment). The
  conformance suite is the gate — run `go test ./...` before relying on it.
- **Wire number bound (float64):** `encoding/json` decodes every JSON
  number to `float64`, which is exact for integers only up to 2^53 − 1.
  `FromWireJSON`/`FromWire` therefore reject JSON numbers that are
  fractional or exceed 2^53 − 1 as `invalid_structure`. Schema-v1 ids are
  tiny, so the bound has no practical effect; structural `FromWire` input
  built in Go may carry full-range native `int`/`uint64` values.
- **NFC approximation:** the stdlib has no NFC normalizer, so `FromLatin`
  composes decomposed sequences over exactly the profile alphabet of
  ROMANIZATION.md §2 (see `composeTable` in `romanization.go`). Anything
  outside that alphabet is rejected as `unsupported` either way, so the
  approximation is behaviorally exact for the profile.
