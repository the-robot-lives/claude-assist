"""ithkuil -- Python REFERENCE codec for the iffywow New Ithkuil coordinate SDK.

Small, inspectable, stdlib-only.  This package is the mathematical reference
and independent test oracle for the Elixir production codec; it mirrors the
Elixir ``Ithkuil`` API surface and drives the shared conformance vectors.
It is NEVER in the live render path.

Public API (CODEC.md section 5)::

    from_latin(text)                 -> Word
    to_latin(word_or_wire)           -> str
    to_integer(word_or_wire)         -> int
    from_integer(n)                  -> Word
    to_integer_string(word_or_wire)  -> str     # decimal-string boundary
    from_integer_string(s)           -> Word
    to_scene(word_or_wire, ...)      -> dict    # render model
    svg.render(model, mode)          -> str
    svg.extract_coordinate(svg_text) -> list | None

Laws (enforced by tests against conformance/*.jsonl)::

    from_integer(to_integer(c))                          == c
    to_latin(from_latin(w))                              == canonicalize(w)
    svg.extract_coordinate(svg.render(to_scene(c)))      == wire(c)
"""

from __future__ import annotations

from typing import Optional, Union

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
    "codec",
    "coord",
    "from_integer",
    "from_integer_string",
    "from_latin",
    "romanization",
    "scene",
    "svg",
    "to_integer",
    "to_integer_string",
    "to_latin",
    "to_scene",
    "word_from_wire",
    "word_to_wire",
]


def from_latin(text: str) -> Word:
    """Romanized New Ithkuil text -> canonical Word (supported subset only)."""
    return romanization.from_latin(text)


def to_latin(value: Union[str, list, Word]) -> str:
    """Canonical word -> romanized text (supported subset only)."""
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


def to_scene(
    value: Union[str, list, Word],
    latinized: Optional[str] = None,
    integer: Optional[str] = None,
) -> dict:
    """Word -> deterministic render model (matches web/src/scene.js)."""
    return scene.compile_scene(value, latinized=latinized, integer=integer)
