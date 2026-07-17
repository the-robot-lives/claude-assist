"""Deterministic random-word generator shared by the property tests and the
vector regeneration helper.

Uses stdlib ``random.Random`` with an explicit seed: the Mersenne Twister
stream is specified and stable across CPython versions and platforms, so
"random" here still means reproducible.  Nesting is capped at two modifier
levels (glyph -> modifier -> modifier), which exercises the recursive socket
grammar without unbounded depth.
"""

from __future__ import annotations

import random

from ithkuil import coord


def random_modifier(rnd: random.Random, remaining: int) -> coord.Modifier:
    diacritics = tuple(rnd.randrange(10) for _ in range(rnd.randrange(4)))
    return coord.Modifier(
        rnd.randrange(13),
        rnd.randrange(4),
        diacritics,
        random_sockets(rnd, remaining),
    )


def random_sockets(rnd: random.Random, remaining: int) -> tuple:
    """Canonical socket tuple: distinct ids, sorted ascending, all occupied."""
    if remaining <= 0:
        return ()
    count = rnd.choice((0, 0, 1, 1, 2, 3))
    ids = sorted(rnd.sample(range(8), count))
    return tuple(coord.Socket(i, random_modifier(rnd, remaining - 1)) for i in ids)


def random_glyph(rnd: random.Random) -> coord.Glyph:
    return coord.Glyph(
        rnd.randrange(6),
        rnd.randrange(40),
        rnd.randrange(4),
        random_sockets(rnd, 2),
    )


def random_word(rnd: random.Random) -> coord.Word:
    return coord.Word(1, tuple(random_glyph(rnd) for _ in range(rnd.randrange(4))))
