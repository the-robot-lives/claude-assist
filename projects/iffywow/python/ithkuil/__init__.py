"""ithkuil -- Python REFERENCE codec for the iffywow New Ithkuil coordinate SDK.

Small, inspectable, stdlib-only.  This package is the mathematical reference
and independent test oracle for the Elixir production codec; it mirrors the
Elixir ``Ithkuil`` API surface and drives the shared conformance vectors.
It is NEVER in the live render path.

Public API (SDK-INTERFACE.md section 2; also CODEC.md section 5)::

    from_latin(text)                 -> Word    # romanization profile core-v1
    to_latin(word_or_wire)           -> str     # canonical spelling (lowercase NFC)
    to_integer(word_or_wire)         -> int
    from_integer(n)                  -> Word    # strict
    to_integer_string(word_or_wire)  -> str     # decimal-string boundary
    from_integer_string(s)           -> Word
    to_bytes(word_or_wire)           -> bytes   # canonical codec-v1 ser(word)
    from_bytes(data)                 -> Word    # strict
    to_wire(word_or_wire)            -> list    # canonical tagged arrays
    from_wire(value)                 -> Word    # LENIENT-canonicalizing
    to_wire_json(word_or_wire)       -> str     # canonical wire JSON text
    from_wire_json(text)             -> Word    # lenient
    validate(value)                  -> Word    # structural check (native Word)
    canonicalize(value)              -> Word    # lenient repair + validate
    to_scene(word_or_wire, ...)      -> dict    # render model (extension)
    svg.render(model, mode)          -> str
    svg.extract_coordinate(svg_text) -> list | None

Strictness boundary (SDK-INTERFACE.md): byte/integer inputs are STRICT (one
meaning, one representation); wire/JSON inputs are LENIENT but canonicalizing
(sockets sorted, ``[id, null]`` empties dropped; duplicates always error).

Laws (enforced by tests against conformance/*.jsonl)::

    from_integer(to_integer(c))                          == c
    from_bytes(to_bytes(c))                              == c
    from_wire(to_wire(c))                                == c
    from_wire_json(to_wire_json(c))                      == c
    to_latin(from_latin(w))                              == canonical(w)
    svg.extract_coordinate(svg.render(to_scene(c)))      == wire(c)
"""

from __future__ import annotations

import json as _json
from typing import Any, Optional, Union

from . import codec, coord, romanization, scene, svg
from .coord import (
    Glyph,
    IthkuilError,
    Modifier,
    Socket,
    Word,
    canonical_wire,
    word_from_wire,
    word_to_wire,
)

SCHEMA_VERSION = scene.SCHEMA_VERSION

__all__ = [
    "SCHEMA_VERSION",
    "Glyph",
    "IthkuilError",
    "Modifier",
    "Socket",
    "Word",
    "canonical_wire",
    "canonicalize",
    "codec",
    "coord",
    "from_bytes",
    "from_integer",
    "from_integer_string",
    "from_latin",
    "from_wire",
    "from_wire_json",
    "romanization",
    "scene",
    "svg",
    "to_bytes",
    "to_integer",
    "to_integer_string",
    "to_latin",
    "to_scene",
    "to_wire",
    "to_wire_json",
    "validate",
    "word_from_wire",
    "word_to_wire",
]


def from_latin(text: str) -> Word:
    """Romanized New Ithkuil text -> canonical Word (romanization profile
    core-v1; everything outside the profile raises ``unsupported``)."""
    return romanization.from_latin(text)


def to_latin(value: Union[str, list, Word]) -> str:
    """Coordinate -> canonical spelling (lowercase NFC; profile core-v1)."""
    return romanization.to_latin(value)


def to_integer(value: Union[str, list, Word]) -> int:
    """Word -> natural-number code (codec-v1 ranking)."""
    return codec.to_integer(value)


def from_integer(n: int) -> Word:
    """Natural-number code -> Word; only canonical encodings of valid words
    decode successfully."""
    return codec.from_integer(n)


def to_integer_string(value: Union[str, list, Word]) -> str:
    """Word -> unsigned decimal string (the cross-boundary integer form)."""
    return codec.to_integer_string(value)


def from_integer_string(s: str) -> Word:
    """Unsigned decimal string -> Word."""
    return codec.from_integer_string(s)


def to_bytes(value: Union[str, list, Word]) -> bytes:
    """Word -> canonical codec-v1 byte serialization ``ser(word)``."""
    return codec.word_to_bytes(value)


def from_bytes(data: Union[bytes, bytearray]) -> Word:
    """Strict byte decode: minimal varints, sorted sockets, no trailing
    bytes -- only the canonical serialization of a valid word succeeds."""
    return codec.word_from_bytes(data)


def to_wire(value: Union[str, list, Word]) -> list:
    """Word -> canonical JSON tagged-array wire form (plain lists/ints)."""
    return coord.canonical_wire(value)


def from_wire(value: Union[str, list, Word]) -> Word:
    """Lenient-canonicalizing wire parse: accepts unsorted sockets and
    ``[id, null]`` empties (empties dropped, sockets sorted); duplicate
    sockets always error.  Accepts structural wire arrays, wire JSON text,
    or a ``Word`` (passed through)."""
    return coord.word_from_wire(value)


def to_wire_json(value: Union[str, list, Word]) -> str:
    """Word -> canonical wire-form JSON text (compact, non-ASCII literal --
    matches JS ``JSON.stringify`` of the same coordinate)."""
    return _json.dumps(coord.canonical_wire(value), separators=(",", ":"), ensure_ascii=False)


def from_wire_json(text: str) -> Word:
    """Wire-form JSON text -> Word.  Same lenient-canonicalizing rules as
    :func:`from_wire`; non-text input or unparseable JSON raises
    ``invalid_structure``."""
    if not isinstance(text, str):
        raise IthkuilError(
            "invalid_structure", f"wire JSON must be text, got {type(text).__name__}"
        )
    return coord.word_from_wire(text)


def validate(value: Any) -> Word:
    """Structural check of a language-native coordinate value.

    Python's native coordinate value is :class:`Word`, whose (frozen)
    constructors already enforce every canonical-form invariant -- so any
    ``Word`` instance is canonical by construction and passes through.
    Anything else raises ``invalid_structure``; use :func:`canonicalize`
    for lenient repair of wire data instead.
    """
    if not isinstance(value, Word):
        raise IthkuilError(
            "invalid_structure",
            f"expected an ithkuil.Word, got {type(value).__name__} "
            "(use canonicalize() for wire arrays / JSON text)",
        )
    return value


def canonicalize(value: Union[str, list, Word]) -> Word:
    """Lenient repair + validate: sockets sorted ascending, ``[id, null]``
    empties dropped; duplicate sockets always error.  Accepts a ``Word``,
    a wire array, or wire JSON text."""
    return coord.word_from_wire(value)


def to_scene(
    value: Union[str, list, Word],
    latinized: Optional[str] = None,
    integer: Optional[str] = None,
) -> dict:
    """Word -> deterministic render model (matches web/src/scene.js)."""
    return scene.compile_scene(value, latinized=latinized, integer=integer)
