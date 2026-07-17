"""Canonical coordinate tuple: frozen dataclasses + wire-form conversion.

Mirrors ``web/src/coordinate.js`` and CODEC.md section 2 (schema v1).

Canonical tuple (Python form)::

    Word(version, (Glyph(character_class, base, orientation, sockets), ...))
    Socket(socket_id, Modifier(shape, orientation, diacritics, sockets))

Canonical-form invariants (enforced by the dataclass constructors):

* ``version >= 1``; ``orientation in 0..3``; ``socket_id in 0..7``.
* Sockets sorted strictly ascending by ``socket_id`` (duplicates invalid).
* EMPTY SOCKETS ARE OMITTED. There is no "empty" Socket value; a Socket
  always carries a Modifier. The wire form ``[id, null]`` is accepted on
  *input* at the JSON boundary (``word_from_wire``) and dropped during
  canonicalization -- one meaning, one representation.

JSON wire form (tagged arrays, order-preserving)::

    ["ithkuil-word", version, [glyph, ...]]
    ["glyph", character_class, base, orientation, [socket, ...]]
    [socket_id, null | modifier]
    ["modifier", shape, orientation, [diacritic_id, ...], [socket, ...]]

All rejection paths raise :class:`IthkuilError` (a ``ValueError`` subclass)
whose message starts with a stable machine-readable code, e.g.
``"invalid_orientation: invalid coordinate at $[2][0][3]: orientation must
be 0..3"``. The codes are shared with ``conformance/invalid_inputs.jsonl``.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, List, Optional, Tuple, Union

WORD_TAG = "ithkuil-word"
GLYPH_TAG = "glyph"
MODIFIER_TAG = "modifier"
MAX_SOCKET_ID = 7
MAX_ORIENTATION = 3


class IthkuilError(ValueError):
    """``ValueError`` carrying a stable, machine-readable error code.

    ``str(err)`` always begins with ``"<code>: "`` so conformance tests can
    assert on either the ``code`` attribute or the message text.
    """

    def __init__(self, code: str, message: str) -> None:
        super().__init__(f"{code}: {message}")
        self.code = code


# --------------------------------------------------------------------------
# Constructor-level validation helpers (strict: canonical values only).
# --------------------------------------------------------------------------


def _require_nat(value: Any, what: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise IthkuilError(
            "invalid_structure", f"{what} must be a non-negative integer, got {value!r}"
        )
    return value


def _require_orientation(value: Any, what: str) -> int:
    n = _require_nat(value, what)
    if n > MAX_ORIENTATION:
        raise IthkuilError("invalid_orientation", f"{what} must be 0..{MAX_ORIENTATION}, got {n}")
    return n


def _require_sockets(items: Any, what: str) -> Tuple["Socket", ...]:
    sockets = tuple(items)
    prev = -1
    for s in sockets:
        if not isinstance(s, Socket):
            raise IthkuilError("invalid_structure", f"{what} must contain Socket instances")
        if s.socket_id == prev:
            raise IthkuilError("duplicate_socket", f"duplicate socket {s.socket_id}")
        if s.socket_id < prev:
            raise IthkuilError(
                "unsorted_sockets",
                f"sockets must be sorted strictly ascending (socket {s.socket_id} after {prev})",
            )
        prev = s.socket_id
    return sockets


# --------------------------------------------------------------------------
# Frozen dataclasses -- the canonical tuple.
# Constructors accept any sequence for the collection fields (coerced to
# tuples) but are otherwise STRICT: values must already be canonical.
# Lenient parsing/canonicalization lives in `word_from_wire`.
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class Modifier:
    shape: int
    orientation: int
    diacritics: Tuple[int, ...] = ()
    sockets: Tuple["Socket", ...] = ()

    def __post_init__(self) -> None:
        _require_nat(self.shape, "modifier shape")
        _require_orientation(self.orientation, "modifier orientation")
        object.__setattr__(self, "diacritics", tuple(self.diacritics))
        for d in self.diacritics:
            _require_nat(d, "diacritic id")
        object.__setattr__(self, "sockets", _require_sockets(self.sockets, "modifier sockets"))


@dataclass(frozen=True)
class Socket:
    socket_id: int
    modifier: Modifier

    def __post_init__(self) -> None:
        _require_nat(self.socket_id, "socket id")
        if self.socket_id > MAX_SOCKET_ID:
            raise IthkuilError(
                "invalid_socket_id",
                f"socket id must be 0..{MAX_SOCKET_ID} in schema v1, got {self.socket_id}",
            )
        if not isinstance(self.modifier, Modifier):
            raise IthkuilError(
                "invalid_structure",
                "socket modifier must be a Modifier "
                "(empty sockets are omitted from the canonical form)",
            )


@dataclass(frozen=True)
class Glyph:
    character_class: int
    base: int
    orientation: int
    sockets: Tuple[Socket, ...] = ()

    def __post_init__(self) -> None:
        _require_nat(self.character_class, "glyph character class")
        _require_nat(self.base, "glyph base")
        _require_orientation(self.orientation, "glyph orientation")
        object.__setattr__(self, "sockets", _require_sockets(self.sockets, "glyph sockets"))


@dataclass(frozen=True)
class Word:
    version: int
    glyphs: Tuple[Glyph, ...] = ()

    def __post_init__(self) -> None:
        if isinstance(self.version, bool) or not isinstance(self.version, int) or self.version < 1:
            raise IthkuilError(
                "invalid_version", f"schema version must be a positive integer, got {self.version!r}"
            )
        glyphs = tuple(self.glyphs)
        for g in glyphs:
            if not isinstance(g, Glyph):
                raise IthkuilError("invalid_structure", "word glyphs must be Glyph instances")
        object.__setattr__(self, "glyphs", glyphs)


# --------------------------------------------------------------------------
# Wire parsing (lenient input -> canonical Word).  Mirrors coordinate.js.
# --------------------------------------------------------------------------


def _fail(code: str, msg: str, path: str) -> None:
    raise IthkuilError(code, f"invalid coordinate at {path}: {msg}")


def _nat(value: Any, path: str) -> int:
    """Non-negative integer at a JSON boundary.

    JS ``Number.isInteger(2.0)`` is true (JSON cannot distinguish 2.0 from
    2), so integral floats are accepted and normalized to int.  Booleans are
    rejected (JS ``Number.isInteger(true)`` is false).
    """
    if isinstance(value, bool):
        _fail("invalid_structure", "expected non-negative integer", path)
    if isinstance(value, int):
        if value < 0:
            _fail("invalid_structure", "expected non-negative integer", path)
        return value
    if isinstance(value, float) and value.is_integer() and value >= 0:
        return int(value)
    _fail("invalid_structure", "expected non-negative integer", path)
    raise AssertionError("unreachable")


def _orient(value: Any, path: str) -> int:
    n = _nat(value, path)
    if n > MAX_ORIENTATION:
        _fail("invalid_orientation", f"orientation must be 0..{MAX_ORIENTATION}", path)
    return n


def word_from_wire(value: Union[str, list, "Word"]) -> Word:
    """Parse a wire coordinate (tagged arrays or JSON text) into a canonical
    :class:`Word`: sockets sorted ascending, duplicates rejected, empty
    sockets (``[id, null]``) dropped.  A ``Word`` passes through unchanged.
    """
    if isinstance(value, Word):
        return value
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError as e:
            raise IthkuilError("invalid_json", f"invalid coordinate: not JSON ({e})") from None
    if not isinstance(value, list) or len(value) != 3 or value[0] != WORD_TAG:
        _fail("invalid_structure", f'expected ["{WORD_TAG}", version, glyphs]', "$")
    version = value[1]
    if isinstance(version, float) and not isinstance(version, bool) and version.is_integer():
        version = int(version)
    if isinstance(version, bool) or not isinstance(version, int) or version < 1:
        _fail("invalid_version", "schema version must be a positive integer", "$[1]")
    if not isinstance(value[2], list):
        _fail("invalid_structure", "glyph list must be an array", "$[2]")
    glyphs = tuple(_parse_glyph(g, f"$[2][{i}]") for i, g in enumerate(value[2]))
    return Word(version, glyphs)


def _parse_glyph(g: Any, path: str) -> Glyph:
    if not isinstance(g, list) or len(g) != 5 or g[0] != GLYPH_TAG:
        _fail("invalid_structure", f'expected ["{GLYPH_TAG}", class, base, orientation, sockets]', path)
    return Glyph(
        _nat(g[1], f"{path}[1]"),
        _nat(g[2], f"{path}[2]"),
        _orient(g[3], f"{path}[3]"),
        _parse_sockets(g[4], f"{path}[4]"),
    )


def _parse_sockets(items: Any, path: str) -> Tuple[Socket, ...]:
    if not isinstance(items, list):
        _fail("invalid_structure", "sockets must be an array", path)
    seen = set()
    parsed: List[Tuple[int, Optional[Modifier]]] = []
    for i, s in enumerate(items):
        p = f"{path}[{i}]"
        if not isinstance(s, list) or len(s) != 2:
            _fail("invalid_structure", "expected [socket_id, null | modifier]", p)
        sid = _nat(s[0], f"{p}[0]")
        if sid > MAX_SOCKET_ID:
            _fail("invalid_socket_id", f"socket id must be 0..{MAX_SOCKET_ID} in schema v1", f"{p}[0]")
        if sid in seen:  # duplicates rejected even when one side is null
            _fail("duplicate_socket", f"duplicate socket {sid}", p)
        seen.add(sid)
        modifier = None if s[1] is None else _parse_modifier(s[1], f"{p}[1]")
        parsed.append((sid, modifier))
    parsed.sort(key=lambda pair: pair[0])  # canonical ordering
    return tuple(Socket(sid, mod) for sid, mod in parsed if mod is not None)  # empties omitted


def _parse_modifier(m: Any, path: str) -> Modifier:
    if not isinstance(m, list) or len(m) != 5 or m[0] != MODIFIER_TAG:
        _fail(
            "invalid_structure",
            f'expected ["{MODIFIER_TAG}", shape, orientation, diacritics, sockets]',
            path,
        )
    if not isinstance(m[3], list):
        _fail("invalid_structure", "diacritics must be an array", f"{path}[3]")
    return Modifier(
        _nat(m[1], f"{path}[1]"),
        _orient(m[2], f"{path}[2]"),
        tuple(_nat(d, f"{path}[3][{i}]") for i, d in enumerate(m[3])),
        _parse_sockets(m[4], f"{path}[4]"),
    )


# --------------------------------------------------------------------------
# Canonical Word -> wire (tagged arrays).
# --------------------------------------------------------------------------


def word_to_wire(word: Word) -> list:
    """Canonical wire form: plain lists, ints, tag strings -- ``json.dumps``
    of the result matches JS ``JSON.stringify`` of the same coordinate."""
    return [WORD_TAG, word.version, [_glyph_wire(g) for g in word.glyphs]]


def _glyph_wire(g: Glyph) -> list:
    return [GLYPH_TAG, g.character_class, g.base, g.orientation, [_socket_wire(s) for s in g.sockets]]


def _socket_wire(s: Socket) -> list:
    return [s.socket_id, _modifier_wire(s.modifier)]


def _modifier_wire(m: Modifier) -> list:
    return [MODIFIER_TAG, m.shape, m.orientation, list(m.diacritics), [_socket_wire(s) for s in m.sockets]]


def canonical_wire(value: Union[str, list, Word]) -> list:
    """Any accepted input form -> canonical wire form."""
    return word_to_wire(word_from_wire(value))


def as_word(value: Union[str, list, Word]) -> Word:
    """Coerce ``Word`` | wire list | JSON text to a canonical :class:`Word`."""
    return word_from_wire(value)
