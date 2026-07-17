"""Romanization subset: round-trip law + honest "unsupported" refusals.

Non-ASCII test graphemes are written as explicit ``\\u`` escapes so the
composed/decomposed distinction survives any source-encoding round trip.
"""

from __future__ import annotations

import unicodedata

import pytest

from ithkuil import coord, from_latin, romanization, to_latin


def test_round_trip_law_over_full_alphabet():
    # to_latin(from_latin(w)) == w for every supported grapheme at once
    text = "".join(romanization.CONSONANTS) + "".join(romanization.VOWELS)
    word = from_latin(text)
    assert to_latin(word) == text
    assert len(word.glyphs) == len(romanization.CONSONANTS) + len(romanization.VOWELS)


def test_alphabet_tables_are_canonical_nfc():
    for g in romanization.CONSONANTS + romanization.VOWELS:
        assert g == unicodedata.normalize("NFC", g)
    # 31 consonants + 9 vowels, no collisions
    assert len(set(romanization.CONSONANTS)) == 31
    assert len(set(romanization.VOWELS)) == 9


def test_grapheme_ids_are_stable():
    word = from_latin("pa")
    p, a = word.glyphs
    assert (p.character_class, p.base) == (romanization.CHARACTER_CLASS_CONSONANT, 0)
    assert (a.character_class, a.base) == (romanization.CHARACTER_CLASS_VOWEL, 0)
    assert p.orientation == 0 and p.sockets == ()


def test_empty_string_is_the_empty_word():
    assert from_latin("") == coord.Word(1, ())
    assert to_latin(coord.Word(1, ())) == ""


def test_nfc_normalization_accepts_decomposed_input():
    decomposed = "š"  # s + combining caron
    precomposed = "š"  # s-caron
    assert unicodedata.normalize("NFC", decomposed) == precomposed
    word = from_latin(decomposed)
    assert to_latin(word) == precomposed


@pytest.mark.parametrize("bad", ["A", "q", " ", "p b", "á"])  # a-acute last
def test_unsupported_graphemes_refuse_rather_than_guess(bad):
    with pytest.raises(ValueError) as e:
        from_latin(bad)
    assert str(e.value).startswith("unsupported: ")


def test_unsupported_word_features_refuse_rather_than_guess():
    oriented = coord.Word(1, (coord.Glyph(0, 0, 1, ()),))
    with pytest.raises(ValueError) as e:
        to_latin(oriented)
    assert str(e.value).startswith("unsupported: ")

    socketed = coord.Word(
        1, (coord.Glyph(0, 0, 0, (coord.Socket(1, coord.Modifier(0, 0, (), ())),)),)
    )
    with pytest.raises(ValueError) as e:
        to_latin(socketed)
    assert str(e.value).startswith("unsupported: ")

    unknown_base = coord.Word(1, (coord.Glyph(0, 999, 0, ()),))
    with pytest.raises(ValueError) as e:
        to_latin(unknown_base)
    assert str(e.value).startswith("unsupported: ")
