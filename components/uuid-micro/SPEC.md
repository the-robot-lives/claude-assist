# uuid-micro Spec

## Token Alphabet

The token alphabet is the concatenation of these inclusive Unicode ranges:

| Range | Block | Count |
| --- | --- | ---: |
| `U+10980..U+1099F` | Meroitic Hieroglyphs | 32 |
| `U+13000..U+1342F` | Egyptian Hieroglyphs | 1072 |
| `U+13460..U+143FF` | Egyptian Hieroglyphs Extended-A | 4000 |
| `U+14400..U+1467F` | Anatolian Hieroglyphs | 640 |

Total alphabet size: `5744`.

The gap `U+13430..U+1345F` is deliberately excluded because it contains Egyptian Hieroglyph format controls, not simple printable token glyphs.

## Encoding

Given UUID bytes `b[0..15]` in RFC textual/network order:

```text
n = unsigned-big-endian-u128(b)
base = 5744
length = 4
residue = n mod base^length

for i in 0..length:
  digit[i] = residue mod base
  residue = floor(residue / base)

token = reverse(map_token_digit(digit))
```

`map_token_digit/1` walks the concatenated ranges in order. If a digit lands past the end of the current range, subtract that range's count and continue to the next range.

## Validation

A generated `uuid-micro` token is valid when it has exactly four Unicode scalar values and every scalar is in the token alphabet. Decoders should not attempt to recover the UUID because the mapping intentionally drops information.
