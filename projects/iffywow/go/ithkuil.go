// Package ithkuil is the Go core SDK for the iffywow New Ithkuil codec:
// conversions between canonical coordinate tuples (Word), codec-v1 bytes,
// arbitrary-precision integers, wire JSON, and romanized text.
//
// Normative documents (repo root, one level above this module):
//
//   - SDK-INTERFACE.md — the language-agnostic operation contract (v1)
//   - CODEC.md         — byte/integer encoding, codec-v1 (normative)
//   - ROMANIZATION.md  — romanization profile core-v1 (normative)
//   - conformance/     — golden vectors, the arbiter
//
// The core SDK is conversions only — no scene graphs, no SVG, no rendering.
//
// Value domains and operations (SDK-INTERFACE.md §§1–2):
//
//	Validate(Word) error                     structural check (strict)
//	Canonicalize(Word) (Word, error)         lenient repair: sort sockets, then validate
//	ToBytes(Word) []byte                     canonical codec-v1 ser(word)
//	FromBytes([]byte) (Word, error)          strict decode
//	ToInteger(Word) *big.Int                 E(t) per CODEC.md §3
//	FromInteger(*big.Int) (Word, error)      strict decode
//	ToIntegerString(Word) string             unsigned decimal (the boundary form)
//	FromIntegerString(string) (Word, error)  rejects sign/empty/non-digits
//	ToWire(Word) []interface{}               canonical tagged arrays
//	FromWire([]interface{}) (Word, error)    lenient-canonicalizing
//	ToWireJSON(Word) ([]byte, error)         canonical wire JSON text
//	FromWireJSON([]byte) (Word, error)       lenient-canonicalizing
//	FromLatin(string) (Word, error)          romanization profile core-v1
//	ToLatin(Word) (string, error)            canonical spelling, NFC
//
// Strictness boundary (settled): byte and integer inputs are STRICT — one
// meaning, one representation; wire/JSON and language-native inputs are
// LENIENT but canonicalizing (sockets sorted, [id, null] empties dropped).
// Duplicated sockets are always an error, never repaired.
//
// Errors are *Error values carrying a stable Code from the SDK-INTERFACE.md
// §3 registry; match them with errors.Is against the exported sentinels
// (ErrTruncated, ErrDuplicateSocket, ErrUnsupported, ...).
//
// This package is dependency-free: standard library only (math/big,
// encoding/json).
package ithkuil
