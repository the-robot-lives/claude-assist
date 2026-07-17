"""Romanization profile core-v1: New Ithkuil (Ithkuil IV) latin <-> coordinate.

Normative specification: ``../../ROMANIZATION.md``;
``../../conformance/latin_to_coordinate.jsonl`` is the arbiter.  This module
mirrors the Elixir ``Ithkuil.Romanization`` layer (the origin of the profile)
exactly: identical tables, identical coordinates, identical canonical
spellings.

Scope (deliberately *partial*): core-v1 accepts exactly one word shape -- an
unconcatenated formative ``Vv Cr Vr Ca Vc`` (slots II, III, IV, VI, IX) with
closed tables per slot.  Everything else (Slot I Cc, affixes, VnCn, stress,
glottal stop, adjuncts, multiple words, ...) is rejected with the stable
error code ``unsupported``; the profile never guesses.  The grapheme-level
transliteration previously shipped by this module is superseded (it was not
part of any profile).

Pipeline (ROMANIZATION.md section 1): trim -> NFC -> lowercase, then segment
into maximal same-class runs, require exactly five alternating runs (vowel
first), look each slot up in its closed table, and emit one glyph of a
schema-v1 word (section 6, provisional but frozen for core-v1)::

    word                     = version 1, exactly one glyph
    glyph.character_class    = 0                       (formative)
    glyph.base               = root code (bijective base-27 over section 2.3)
    glyph.orientation        = stem                    (0..3, from Vv)
    socket 0 modifier        = shape: specification, orientation: function + 2*version
    socket 1 modifier        = shape: perspective, orientation 0
    socket 2 modifier        = shape: case index (0..8), orientation 0

``to_latin`` accepts exactly coordinates of that shape (wire inputs are
canonicalized first) and emits the canonical spelling: lowercase NFC
concatenation ``Vv || Cr || Vr || Ca || Vc``.
"""

from __future__ import annotations

import unicodedata
from typing import Dict, List, Tuple, Union

from . import coord as _coord
from .coord import Glyph, IthkuilError, Modifier, Socket, Word


def _nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s)


# ---------------------------------------------------------------------------
# Character inventories (ROMANIZATION.md section 2).  All entries are single
# precomposed codepoints; tables are NFC-normalized at load so lookups are
# canonical regardless of how this source file was encoded.
# ---------------------------------------------------------------------------

#: Vowels (class V) -- 9 codepoints (section 2.1).
VOWELS: Tuple[str, ...] = tuple(_nfc(v) for v in ("a", "e", "i", "o", "u", "ä", "ë", "ö", "ü"))

#: Stress-marked vowels (section 2.2) -- Slot X stress, always rejected.
STRESS_VOWELS: Tuple[str, ...] = tuple(
    _nfc(v) for v in ("á", "é", "í", "ó", "ú", "â", "ê", "î", "ô", "û")
)

#: Root inventory -- 27 consonants (section 2.3, first table).  THE ORDER IS
#: NORMATIVE: bijective base-27 digit value = 1-based position.
ROOT_CONSONANTS: Tuple[str, ...] = tuple(
    _nfc(c)
    for c in (
        "p", "b", "t", "d", "k", "g", "f", "v", "ţ",
        "ḑ", "s", "z", "c", "ẓ", "š", "ž", "č", "j",
        "ç", "x", "ļ", "l", "r", "ř", "m", "n", "ň",
    )
)

ROOT_BASE = len(ROOT_CONSONANTS)  # 27
MAX_ROOT_CLUSTER = 4
#: Valid root codes are 1..551880 (= 27 + 27**2 + 27**3 + 27**4).
MAX_ROOT_CODE = sum(ROOT_BASE ** k for k in range(1, MAX_ROOT_CLUSTER + 1))

#: Additional segmenter consonants (section 2.3, second table): classify as
#: consonants for run segmentation but are valid only where a table row
#: admits them (``w``/``y`` in Ca; ``h``/``'`` nowhere).
SEGMENT_ONLY_CONSONANTS: Tuple[str, ...] = ("h", "w", "y", "'")

_ROOT_DIGITS: Dict[str, int] = {c: i + 1 for i, c in enumerate(ROOT_CONSONANTS)}
_VOWEL_SET = frozenset(VOWELS)
_STRESS_SET = frozenset(STRESS_VOWELS)
_CONSONANT_SET = frozenset(ROOT_CONSONANTS) | frozenset(SEGMENT_ONLY_CONSONANTS)

# ---------------------------------------------------------------------------
# Lookup tables (ROMANIZATION.md section 4; closed, exact rows).
# ---------------------------------------------------------------------------

#: Vv -- stem + version (section 4.1).  Version: 0 = PRC, 1 = CPT.
VV: Dict[str, Tuple[int, int]] = {
    _nfc(k): v
    for k, v in {
        "a": (1, 0), "ä": (1, 1),
        "e": (2, 0), "i": (2, 1),
        "u": (3, 0), "ü": (3, 1),
        "o": (0, 0), "ö": (0, 1),
    }.items()
}
_VV_INV: Dict[Tuple[int, int], str] = {v: k for k, v in VV.items()}

#: Vr -- function + specification (section 4.2; context fixed at EXS).
#: Function: 0 = STA, 1 = DYN.  Spec: 0 = BSC, 1 = CTE, 2 = CSV, 3 = OBJ.
VR: Dict[str, Tuple[int, int]] = {
    _nfc(k): v
    for k, v in {
        "a": (0, 0), "ä": (0, 1), "e": (0, 2), "i": (0, 3),
        "u": (1, 0), "ü": (1, 1), "o": (1, 2), "ö": (1, 3),
    }.items()
}
_VR_INV: Dict[Tuple[int, int], str] = {v: k for k, v in VR.items()}

#: Ca -- perspective (section 4.3): M, G, N, A.
CA: Dict[str, int] = {"l": 0, "r": 1, "w": 2, "y": 3}
_CA_INV: Dict[int, str] = {v: k for k, v in CA.items()}

#: Vc -- case index 0..8 (section 4.4): THM INS ABS AFF STM EFF ERG DAT IND.
#: ``ëi`` is the two-codepoint digraph matched as the whole vowel run.
VC: Tuple[str, ...] = tuple(_nfc(v) for v in ("a", "ä", "e", "i", "ëi", "ö", "o", "ü", "u"))
_VC_INDEX: Dict[str, int] = {v: i for i, v in enumerate(VC)}


def _unsupported(detail: str) -> IthkuilError:
    return IthkuilError("unsupported", detail)


# ---------------------------------------------------------------------------
# from_latin
# ---------------------------------------------------------------------------


def from_latin(text: str) -> Word:
    """Romanized New Ithkuil formative -> canonical :class:`Word`.

    Preprocessing (section 1, exact order): trim, NFC-normalize, lowercase.
    Anything outside profile core-v1 raises :class:`IthkuilError` with code
    ``"unsupported"``; a non-string input raises code ``"invalid_structure"``
    (out of the operation's value domain entirely, per section 8).
    """
    if not isinstance(text, str):
        raise IthkuilError(
            "invalid_structure", f"romanized input must be a string, got {type(text).__name__}"
        )
    word = _nfc(text.strip()).lower()
    vv, cr, vr, ca, vc = _shape(_segment(word))

    stem, version = _table(VV, vv, "Vv")
    base = _root_code(cr)
    function, spec = _table(VR, vr, "Vr")
    perspective = _table(CA, ca, "Ca")
    case_index = _VC_INDEX.get(vc)
    if case_index is None:
        raise _unsupported(f"Vc run {vc!r} is not a case vowel form of the profile")

    return Word(
        1,
        (
            Glyph(
                0,
                base,
                stem,
                (
                    Socket(0, Modifier(spec, function + 2 * version, (), ())),
                    Socket(1, Modifier(perspective, 0, (), ())),
                    Socket(2, Modifier(case_index, 0, (), ())),
                ),
            ),
        ),
    )


def _segment(word: str) -> List[Tuple[str, str]]:
    """Split the preprocessed word into maximal same-class runs
    (section 3).  Every codepoint must classify; the empty word rejects."""
    if not word:
        raise _unsupported("empty word")
    runs: List[Tuple[str, str]] = []
    for ch in word:
        kind = _classify(ch)
        if runs and runs[-1][0] == kind:
            runs[-1] = (kind, runs[-1][1] + ch)
        else:
            runs.append((kind, ch))
    return runs


def _classify(ch: str) -> str:
    if ch in _STRESS_SET:
        raise _unsupported(f"stress-marked vowel {ch!r} (Slot X stress is out of profile)")
    if ch in _VOWEL_SET:
        return "v"
    if ch in _CONSONANT_SET:
        return "c"
    raise _unsupported(f"character {ch!r} (U+{ord(ch):04X}) is outside the profile inventories")


def _shape(runs: List[Tuple[str, str]]) -> Tuple[str, str, str, str, str]:
    """Exactly five alternating runs, vowel first: Vv Cr Vr Ca Vc."""
    if [kind for kind, _ in runs] != ["v", "c", "v", "c", "v"]:
        raise _unsupported(
            "word shape must be exactly Vv Cr Vr Ca Vc (five alternating runs, vowel first); "
            f"got {len(runs)} run(s)"
        )
    vv, cr, vr, ca, vc = (text for _, text in runs)
    return vv, cr, vr, ca, vc


def _table(table: dict, key: str, slot: str):
    try:
        return table[key]
    except KeyError:
        raise _unsupported(f"{slot} form {key!r} is not in the core-v1 table") from None


def _root_code(cluster: str) -> int:
    """Cr cluster -> bijective base-27 root code (section 5): left fold
    ``acc <- acc*27 + d(c)`` with 1-based digit values, cluster length <= 4."""
    if len(cluster) > MAX_ROOT_CLUSTER:
        raise _unsupported(
            f"root cluster {cluster!r} longer than {MAX_ROOT_CLUSTER} consonants"
        )
    code = 0
    for ch in cluster:
        digit = _ROOT_DIGITS.get(ch)
        if digit is None:
            raise _unsupported(f"consonant {ch!r} is not in the root inventory")
        code = code * ROOT_BASE + digit
    return code


def _root_cluster(base: int) -> str:
    """Root code -> Cr cluster (section 5 decode).  Rejects base 0 and any
    base whose decode exceeds four consonants (i.e. base > 551880)."""
    if isinstance(base, bool) or not isinstance(base, int) or base < 1 or base > MAX_ROOT_CODE:
        raise _unsupported(f"root code {base!r} is outside 1..{MAX_ROOT_CODE}")
    out: List[str] = []
    n = base
    while n > 0:
        digit = (n - 1) % ROOT_BASE + 1
        out.append(ROOT_CONSONANTS[digit - 1])
        n = (n - 1) // ROOT_BASE
    return "".join(reversed(out))


# ---------------------------------------------------------------------------
# to_latin
# ---------------------------------------------------------------------------


def to_latin(value: Union[str, list, Word]) -> str:
    """Coordinate -> canonical spelling (section 7): lowercase NFC
    concatenation ``Vv || Cr || Vr || Ca || Vc``, unique per in-profile
    coordinate.

    Accepts a :class:`Word`, a wire array, or wire JSON text; wire inputs are
    canonicalized first (sockets sorted, ``[id, null]`` empties dropped).
    Any coordinate outside the section 6/7 shape raises ``"unsupported"``.
    """
    word = _coord.as_word(value)

    if word.version != 1 or len(word.glyphs) != 1:
        raise _unsupported(
            "core-v1 romanizes exactly one glyph at schema version 1, got "
            f"version {word.version} with {len(word.glyphs)} glyph(s)"
        )
    g = word.glyphs[0]
    if g.character_class != 0:
        raise _unsupported(f"character class {g.character_class} has no core-v1 romanization")
    if tuple(s.socket_id for s in g.sockets) != (0, 1, 2):
        raise _unsupported(
            "core-v1 requires exactly the three sockets 0, 1, 2, got "
            f"{[s.socket_id for s in g.sockets]}"
        )
    m0, m1, m2 = (s.modifier for s in g.sockets)
    for i, m in enumerate((m0, m1, m2)):
        if m.diacritics or m.sockets:
            raise _unsupported(f"socket {i}: core-v1 modifiers carry no diacritics or child sockets")
    if m0.shape > 3:
        raise _unsupported(f"specification {m0.shape} out of range 0..3")
    if m1.shape > 3 or m1.orientation != 0:
        raise _unsupported("perspective modifier must have shape 0..3 and orientation 0")
    if m2.shape > 8 or m2.orientation != 0:
        raise _unsupported("case modifier must have shape 0..8 and orientation 0")

    # glyph/modifier orientations are 0..3 by Word construction.
    stem = g.orientation
    version, function = divmod(m0.orientation, 2)

    cr = _root_cluster(g.base)
    vv = _VV_INV[(stem, version)]
    vr = _VR_INV[(function, m0.shape)]
    ca = _CA_INV[m1.shape]
    vc = VC[m2.shape]
    return vv + cr + vr + ca + vc
