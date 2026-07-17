"""Romanization layer: New Ithkuil (Ithkuil IV) latin <-> coordinate tuple.

STATUS / COVERAGE (read this before relying on anything here)
=============================================================

New Ithkuil formatives decompose into slots I-IX (+ stress):

    I     Cc    concatenation status
    II    Vv    version + stem (+ Ca-shortcut marking)
    III   Cr    the lexical root
    IV    Vr    function + specification + context
    V     CsVx  slot-V affixes (Ca-stacking)
    VI    Ca    configuration, extension, affiliation, perspective, essence
    VII   VxCs  slot-VII affixes
    VIII  VnCn  valence/phase/level/effect/aspect + mood/case-scope
    IX    Vc/Vf/Vk  case, or format, or illocution + validation
    (X)   stress marks parts-of-speech / relation

Full slot-level morphology is REGISTRY-FIRST work: it lands only once the
``spec/*.yaml`` enum inventories (68 cases, 61 biases, 36 aspects, full Ca,
...) exist and codegen stamps them into all three runtimes.  Neither this
module nor the Elixir layer guesses ahead of the registry -- an integer ID
published for a wrong guess could never be reassigned (enum stability rule).

What IS implemented today -- the subset both codecs can encode confidently:

* Grapheme-level transliteration of the New Ithkuil romanization alphabet.
  Each grapheme maps 1:1 to one glyph ``(character_class, base)`` with
  orientation 0 and no sockets:
    - character class 0: the 31 consonants
      p b t d k g ' f v ţ ḑ s z š ž ç x h ļ c ẓ č j m n ň r l w y ř
    - character class 1: the 9 vowels  a ä e ë i o ö u ü
  Base IDs are the (permanent) positions in the tables below.
* Input is NFC-normalized first, so decomposed forms (e.g. ``s`` +
  U+030C combining caron) are accepted.
* ``to_latin`` inverts exactly; the law
  ``to_latin(from_latin(w)) == canonical(w)`` holds on this subset.

EVERYTHING ELSE -- uppercase, whitespace/word boundaries, stress diacritics
(acute/grave), geminates-as-units, bias adjuncts, actual slot parsing --
raises ``ValueError`` whose message begins ``"unsupported: ..."`` rather
than guessing.  (The error is :class:`ithkuil.coord.IthkuilError` with code
``"unsupported"``, which formats exactly as ``unsupported: <detail>``.)
"""

from __future__ import annotations

import unicodedata
from typing import Dict, Tuple, Union

from . import coord as _coord
from .coord import Glyph, IthkuilError, Word

#: character_class IDs (permanent; never reassigned).
CHARACTER_CLASS_CONSONANT = 0
CHARACTER_CLASS_VOWEL = 1

#: New Ithkuil consonant romanization, base id = index (permanent).
CONSONANTS: Tuple[str, ...] = (
    "p",        # 0
    "b",        # 1
    "t",        # 2
    "d",        # 3
    "k",        # 4
    "g",        # 5
    "'",        # 6   glottal stop
    "f",        # 7
    "v",        # 8
    "ţ",   # 9   t-cedilla  [theta]
    "ḑ",   # 10  d-cedilla  [eth]
    "s",        # 11
    "z",        # 12
    "š",   # 13  s-caron
    "ž",   # 14  z-caron
    "ç",   # 15  c-cedilla
    "x",        # 16
    "h",        # 17
    "ļ",   # 18  l-cedilla
    "c",        # 19  [ts]
    "ẓ",   # 20  z-dot-below [dz]
    "č",   # 21  c-caron
    "j",        # 22  [dezh]
    "m",        # 23
    "n",        # 24
    "ň",   # 25  n-caron
    "r",        # 26
    "l",        # 27
    "w",        # 28
    "y",        # 29
    "ř",   # 30  r-caron
)

#: New Ithkuil vowel romanization, base id = index (permanent).
VOWELS: Tuple[str, ...] = (
    "a",        # 0
    "ä",   # 1  a-diaeresis
    "e",        # 2
    "ë",   # 3  e-diaeresis
    "i",        # 4
    "o",        # 5
    "ö",   # 6  o-diaeresis
    "u",        # 7
    "ü",   # 8  u-diaeresis
)

_GRAPHEME_TO_GLYPH: Dict[str, Tuple[int, int]] = {}
for _i, _c in enumerate(CONSONANTS):
    _GRAPHEME_TO_GLYPH[_c] = (CHARACTER_CLASS_CONSONANT, _i)
for _i, _v in enumerate(VOWELS):
    _GRAPHEME_TO_GLYPH[_v] = (CHARACTER_CLASS_VOWEL, _i)

_GLYPH_TO_GRAPHEME: Dict[Tuple[int, int], str] = {v: k for k, v in _GRAPHEME_TO_GLYPH.items()}


def _unsupported(detail: str) -> IthkuilError:
    return IthkuilError("unsupported", detail)


def from_latin(text: str) -> Word:
    """Romanized text -> canonical :class:`Word` (schema v1).

    Grapheme-level transliteration only (see module docstring).  The empty
    string maps to the empty word.  Anything outside the supported alphabet
    raises ``ValueError("unsupported: ...")``.
    """
    if not isinstance(text, str):
        raise _unsupported(f"romanized input must be a string, got {type(text).__name__}")
    normalized = unicodedata.normalize("NFC", text)
    glyphs = []
    for ch in normalized:
        entry = _GRAPHEME_TO_GLYPH.get(ch)
        if entry is None:
            raise _unsupported(
                f"grapheme {ch!r} (U+{ord(ch):04X}) is outside the implemented "
                "transliteration subset; slot I-IX morphology is registry-first "
                "and not yet encoded"
            )
        character_class, base = entry
        glyphs.append(Glyph(character_class, base, 0, ()))
    return Word(1, tuple(glyphs))


def to_latin(value: Union[str, list, Word]) -> str:
    """Canonical word (Word, wire array, or JSON text) -> romanized text.

    Inverse of :func:`from_latin` on the supported subset; any word feature
    the subset cannot express raises ``ValueError("unsupported: ...")``.
    """
    word = _coord.as_word(value)
    if word.version != 1:
        raise _unsupported(f"romanization is only defined for schema version 1, got {word.version}")
    out = []
    for i, g in enumerate(word.glyphs):
        if g.orientation != 0:
            raise _unsupported(
                f"glyph {i}: orientation {g.orientation} has no romanization in the "
                "implemented subset"
            )
        if g.sockets:
            raise _unsupported(
                f"glyph {i}: socketed modifiers have no romanization in the implemented subset"
            )
        grapheme = _GLYPH_TO_GRAPHEME.get((g.character_class, g.base))
        if grapheme is None:
            raise _unsupported(
                f"glyph {i}: (class {g.character_class}, base {g.base}) is not in the "
                "implemented transliteration tables"
            )
        out.append(grapheme)
    return "".join(out)
