# uuid-micro

`uuid-micro` encodes a UUID into a four-character visual token using only curated printable Unicode sign ranges. It is intended for compact display handles and durable doc-pointer markers, not for lossless UUID storage.

The same algorithm is implemented for:

- Elixir: `elixir/`
- Rust: `rust/`
- Go: `go/`
- Python: `python/`
- Node.js: `nodejs/`

## Algorithm

1. Parse the UUID as 16 big-endian bytes.
2. Interpret those bytes as an unsigned 128-bit integer.
3. Reduce it modulo `5744^4`.
4. Render the result as four base-5744 digits.
5. Map each digit into the concatenated printable token ranges in `SPEC.md`.

This is deterministic but lossy. Store the UUID when identity matters; use the token as a human-facing handle.

Golden fixture:

```text
UUID:       5c692577-ad0c-51f1-992c-759b5e5fffb5
token:      𓳔𔐮𔘟𔄵
codepoints: U+13CD4 U+1442E U+1461F U+14135
residue:    619504546873269
```

## Test

Run package tests directly from each language folder:

```bash
cd rust && cargo test
cd go && go test ./...
cd python && python3 -m unittest discover -s tests
cd nodejs && npm test
cd elixir && mix test
```
