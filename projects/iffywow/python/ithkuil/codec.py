"""codec-v1: term algebra ser/de + integer ranking.  Normative: ../CODEC.md.

Term algebra (tag byte, then payload)::

    0x00  NAT n     minimal unsigned LEB128 varint of n
    0x01  PAIR x y  ser(x) ser(y)
    0x02  LIST      varint k, then k serialized elements
    0x03  BYTES     varint len, then the raw bytes
    0x04  reserved  never emitted in v1; decoders MUST reject

Python term representation (small, inspectable, hashable)::

    ("nat", int)
    ("pair", term, term)
    ("list", (term, ...))
    ("bytes", bytes)

Integer ranking: with ``B = ser(word)`` of byte length ``m``,

    S_m  = (256**m - 1) // 255        # number of strings shorter than m
    E(t) = S_m + V256(B)              # V256 = big-endian base-256 value

Length intervals are disjoint, so decoding recovers ``m`` first (largest
``m`` with ``S_m <= E``), then ``B = E - S_m`` as exactly ``m`` bytes
PRESERVING LEADING ZEROS, then parses the term strictly (canonical varints,
no reserved tags, no trailing bytes, canonical word structure).

Boundary rule: integers cross every language/JSON boundary as unsigned
decimal strings (``to_integer_string`` / ``from_integer_string``).  Python
ints are arbitrary precision, so no further care is needed internally.

Error codes raised here (see conformance/invalid_inputs.jsonl):
``nonminimal_varint``, ``reserved_tag``, ``unknown_tag``, ``truncated``,
``trailing_bytes``, ``invalid_natural_number``, ``invalid_structure`` plus
the word-level codes from :mod:`ithkuil.coord`.
"""

from __future__ import annotations

from typing import Any, Tuple, Union

from . import coord as _coord
from .coord import Glyph, IthkuilError, Modifier, Socket, Word

TAG_NAT = 0x00
TAG_PAIR = 0x01
TAG_LIST = 0x02
TAG_BYTES = 0x03
TAG_RESERVED = 0x04

Term = tuple  # see module docstring for the shape


# --------------------------------------------------------------------------
# Unsigned LEB128 varints (minimal encodings only).
# --------------------------------------------------------------------------


def encode_varint(n: int) -> bytes:
    """Minimal unsigned LEB128: little-endian 7-bit groups, high bit = continue.
    ``0 -> 00``, ``127 -> 7f``, ``128 -> 80 01``, ``300 -> ac 02``."""
    if isinstance(n, bool) or not isinstance(n, int) or n < 0:
        raise IthkuilError("invalid_structure", f"varint value must be a non-negative integer, got {n!r}")
    out = bytearray()
    while True:
        group = n & 0x7F
        n >>= 7
        if n:
            out.append(group | 0x80)
        else:
            out.append(group)
            return bytes(out)


def _read_varint(data: bytes, pos: int) -> Tuple[int, int]:
    """Decode a varint at ``pos``; returns ``(value, new_pos)``.

    Rejects non-minimal encodings: a multi-byte varint whose final (most
    significant) group is zero has a shorter equivalent, e.g. ``80 00`` for 0.
    """
    result = 0
    shift = 0
    start = pos
    while True:
        if pos >= len(data):
            raise IthkuilError("truncated", f"unexpected end of input inside varint at offset {start}")
        b = data[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            if b == 0 and pos - start > 1:
                raise IthkuilError(
                    "nonminimal_varint",
                    f"non-minimal varint at offset {start}: redundant zero continuation group",
                )
            return result, pos
        shift += 7


# --------------------------------------------------------------------------
# Term serialization / strict deserialization.
# --------------------------------------------------------------------------


def serialize_term(term: Term) -> bytes:
    kind = _kind(term)
    if kind == "nat":
        return bytes([TAG_NAT]) + encode_varint(term[1])
    if kind == "pair":
        if len(term) != 3:
            raise IthkuilError("invalid_structure", "pair term must be ('pair', x, y)")
        return bytes([TAG_PAIR]) + serialize_term(term[1]) + serialize_term(term[2])
    if kind == "list":
        items = tuple(term[1])
        payload = b"".join(serialize_term(e) for e in items)
        return bytes([TAG_LIST]) + encode_varint(len(items)) + payload
    if kind == "bytes":
        b = term[1]
        if not isinstance(b, (bytes, bytearray)):
            raise IthkuilError("invalid_structure", "bytes term payload must be bytes")
        b = bytes(b)
        return bytes([TAG_BYTES]) + encode_varint(len(b)) + b
    raise IthkuilError("invalid_structure", f"unknown term kind {kind!r}")


def deserialize_term(data: Union[bytes, bytearray]) -> Term:
    """Strict decode: canonical varints, no reserved/unknown tags, and no
    trailing bytes after the root term."""
    if not isinstance(data, (bytes, bytearray)):
        raise IthkuilError("invalid_structure", f"expected bytes, got {type(data).__name__}")
    data = bytes(data)
    term, pos = _read_term(data, 0)
    if pos != len(data):
        raise IthkuilError(
            "trailing_bytes", f"{len(data) - pos} trailing byte(s) after the root term at offset {pos}"
        )
    return term


def _read_term(data: bytes, pos: int) -> Tuple[Term, int]:
    if pos >= len(data):
        raise IthkuilError("truncated", f"unexpected end of input: expected tag byte at offset {pos}")
    tag = data[pos]
    pos += 1
    if tag == TAG_NAT:
        n, pos = _read_varint(data, pos)
        return ("nat", n), pos
    if tag == TAG_PAIR:
        x, pos = _read_term(data, pos)
        y, pos = _read_term(data, pos)
        return ("pair", x, y), pos
    if tag == TAG_LIST:
        count, pos = _read_varint(data, pos)
        items = []
        for _ in range(count):
            e, pos = _read_term(data, pos)
            items.append(e)
        return ("list", tuple(items)), pos
    if tag == TAG_BYTES:
        length, pos = _read_varint(data, pos)
        if pos + length > len(data):
            raise IthkuilError("truncated", f"bytes payload of length {length} truncated at offset {pos}")
        return ("bytes", data[pos : pos + length]), pos + length
    if tag == TAG_RESERVED:
        raise IthkuilError("reserved_tag", f"reserved tag 0x04 at offset {pos - 1}")
    raise IthkuilError("unknown_tag", f"unknown tag 0x{tag:02x} at offset {pos - 1}")


def _kind(term: Any) -> str:
    if not isinstance(term, (tuple, list)) or len(term) < 2 or not isinstance(term[0], str):
        raise IthkuilError("invalid_structure", f"malformed term: {term!r}")
    return term[0]


# --------------------------------------------------------------------------
# Conformance-vector JSON <-> term (["nat", 0], ["bytes", "<hex>"], ...).
# --------------------------------------------------------------------------


def term_from_json(value: Any) -> Term:
    if not isinstance(value, (list, tuple)) or not value:
        raise IthkuilError("invalid_structure", f"malformed term JSON: {value!r}")
    kind = value[0]
    if kind == "nat":
        return ("nat", int(value[1]))
    if kind == "pair":
        return ("pair", term_from_json(value[1]), term_from_json(value[2]))
    if kind == "list":
        return ("list", tuple(term_from_json(e) for e in value[1]))
    if kind == "bytes":
        return ("bytes", bytes.fromhex(value[1]))
    raise IthkuilError("invalid_structure", f"unknown term kind {kind!r}")


def term_to_json(term: Term) -> list:
    kind = _kind(term)
    if kind == "nat":
        return ["nat", term[1]]
    if kind == "pair":
        return ["pair", term_to_json(term[1]), term_to_json(term[2])]
    if kind == "list":
        return ["list", [term_to_json(e) for e in term[1]]]
    if kind == "bytes":
        return ["bytes", bytes(term[1]).hex()]
    raise IthkuilError("invalid_structure", f"unknown term kind {kind!r}")


# --------------------------------------------------------------------------
# Word <-> term mapping (schema v1, CODEC.md section 2).
# --------------------------------------------------------------------------


def word_to_term(word: Word) -> Term:
    return ("pair", ("nat", word.version), ("list", tuple(_glyph_term(g) for g in word.glyphs)))


def _glyph_term(g: Glyph) -> Term:
    return (
        "list",
        (
            ("nat", g.character_class),
            ("nat", g.base),
            ("nat", g.orientation),
            ("list", tuple(_socket_term(s) for s in g.sockets)),
        ),
    )


def _socket_term(s: Socket) -> Term:
    return ("pair", ("nat", s.socket_id), _modifier_term(s.modifier))


def _modifier_term(m: Modifier) -> Term:
    return (
        "list",
        (
            ("nat", m.shape),
            ("nat", m.orientation),
            ("list", tuple(("nat", d) for d in m.diacritics)),
            ("list", tuple(_socket_term(s) for s in m.sockets)),
        ),
    )


def term_to_word(term: Term) -> Word:
    """Strict term -> Word.  Structural shape checks here; value-range and
    ordering rules (version, orientation, socket ids, sorted-unique sockets)
    are enforced by the :mod:`ithkuil.coord` dataclass constructors, which
    raise the same coded :class:`IthkuilError` values."""
    if _kind(term) != "pair" or len(term) != 3:
        raise IthkuilError("invalid_structure", "word term must be PAIR(NAT version, LIST glyphs)")
    version = _expect_nat(term[1], "word version")
    glyphs_t = _expect_list(term[2], "word glyph list")
    return Word(version, tuple(_term_glyph(g) for g in glyphs_t))


def _expect_nat(term: Term, what: str) -> int:
    if _kind(term) != "nat":
        raise IthkuilError("invalid_structure", f"{what} must be a NAT term")
    return term[1]


def _expect_list(term: Term, what: str) -> tuple:
    if _kind(term) != "list":
        raise IthkuilError("invalid_structure", f"{what} must be a LIST term")
    return tuple(term[1])


def _term_glyph(term: Term) -> Glyph:
    items = _expect_list(term, "glyph")
    if len(items) != 4:
        raise IthkuilError(
            "invalid_structure", "glyph must be LIST[class, base, orientation, sockets]"
        )
    return Glyph(
        _expect_nat(items[0], "glyph character class"),
        _expect_nat(items[1], "glyph base"),
        _expect_nat(items[2], "glyph orientation"),
        _term_sockets(items[3]),
    )


def _term_sockets(term: Term) -> Tuple[Socket, ...]:
    items = _expect_list(term, "socket list")
    sockets = []
    for entry in items:
        if _kind(entry) != "pair" or len(entry) != 3:
            raise IthkuilError("invalid_structure", "socket must be PAIR(NAT id, modifier)")
        sockets.append(Socket(_expect_nat(entry[1], "socket id"), _term_modifier(entry[2])))
    return tuple(sockets)


def _term_modifier(term: Term) -> Modifier:
    items = _expect_list(term, "modifier")
    if len(items) != 4:
        raise IthkuilError(
            "invalid_structure", "modifier must be LIST[shape, orientation, diacritics, sockets]"
        )
    diacritics = tuple(_expect_nat(d, "diacritic") for d in _expect_list(items[2], "diacritic list"))
    return Modifier(
        _expect_nat(items[0], "modifier shape"),
        _expect_nat(items[1], "modifier orientation"),
        diacritics,
        _term_sockets(items[3]),
    )


# --------------------------------------------------------------------------
# Byte-string ranking among all finite byte strings.
# --------------------------------------------------------------------------


def strings_shorter_than(m: int) -> int:
    """``S_m = (256**m - 1) // 255`` -- the number of byte strings with
    length < m (division is exact)."""
    return (256 ** m - 1) // 255


def rank(data: Union[bytes, bytearray]) -> int:
    """``E = S_m + V256(B)`` for ``B = data`` of length ``m``."""
    data = bytes(data)
    return strings_shorter_than(len(data)) + int.from_bytes(data, "big")


def unrank(e: int) -> bytes:
    """Inverse of :func:`rank`: recover the exact byte string, leading zeros
    included.  Every non-negative integer maps to some byte string."""
    if isinstance(e, bool) or not isinstance(e, int) or e < 0:
        raise IthkuilError("invalid_natural_number", f"expected a non-negative integer, got {e!r}")
    m = 0
    s = 0  # S_0
    nxt = 1  # S_1;  S_{m+1} = 256*S_m + 1
    while nxt <= e:
        m += 1
        s = nxt
        nxt = nxt * 256 + 1
    return (e - s).to_bytes(m, "big")


# --------------------------------------------------------------------------
# Public word-level API.
# --------------------------------------------------------------------------


def word_to_bytes(value: Union[str, list, Word]) -> bytes:
    """Canonical codec-v1 serialization of a word."""
    return serialize_term(word_to_term(_coord.as_word(value)))


def word_from_bytes(data: Union[bytes, bytearray]) -> Word:
    """Strict decode: only canonical serializations of valid words succeed."""
    return term_to_word(deserialize_term(data))


def to_integer(value: Union[str, list, Word]) -> int:
    return rank(word_to_bytes(value))


def from_integer(n: int) -> Word:
    if isinstance(n, bool) or not isinstance(n, int) or n < 0:
        raise IthkuilError("invalid_natural_number", f"expected a non-negative integer, got {n!r}")
    return word_from_bytes(unrank(n))


def to_integer_string(value: Union[str, list, Word]) -> str:
    """Unsigned decimal string -- the only sanctioned cross-boundary form."""
    return str(to_integer(value))


def from_integer_string(s: str) -> Word:
    """Parse an unsigned decimal string.  Rejects sign characters, empty
    strings, and anything but ASCII digits 0-9 (``str.isdigit`` alone would
    admit non-ASCII digit code points)."""
    if not isinstance(s, str) or not s or any(c not in "0123456789" for c in s):
        raise IthkuilError("invalid_natural_number", f"expected unsigned decimal string, got {s!r}")
    return from_integer(int(s))
