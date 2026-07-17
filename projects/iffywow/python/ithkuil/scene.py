"""Deterministic scene compiler: coordinate -> render model.

Node-for-node port of ``web/src/scene.js`` (+ its ``registry.js`` and
``util.js`` helpers).  Both compilers must emit the same node IDs, the same
placements, and the same path strings so all runtimes draw the same word
identically (conformance/scene_graph.jsonl, once generated, pins this).

JS-parity notes (load-bearing, do not "fix"):

* ``Math.imul(a, b)`` is the SIGNED 32-bit low word of ``a*b``; ``util.js``
  always reapplies ``>>> 0``, so the effective semantics are the UNSIGNED
  low word.  Here: ``((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF``.
* ``Math.round`` rounds half-way cases toward +Infinity (``Math.round(-2.5)
  === -2``) -- i.e. ``floor(x + 0.5)`` semantics.  Python's ``round()`` is
  banker's rounding, so it is NOT used.  :func:`js_round` returns the integer
  closest to ``x`` with ties toward +Infinity, computed via an exact
  ``x - floor(x)`` comparison.  (Naive ``floor(x + 0.5)`` misrounds the
  pathological double just below 0.5, where float addition carries to 1.0;
  the comparison form matches JS on that input too.)
* Numbers are stringified like JS: integral values print without a decimal
  point (``40`` not ``40.0``); non-integral values use the shortest
  round-trip repr, which Python and JS share for doubles.  :func:`r1`
  therefore normalizes integral results (and ``-0``) to plain ints.
* Arithmetic expression shapes and evaluation order (including the order of
  ``rand()`` calls) are transcribed verbatim from the JS so IEEE-754 results
  are bit-identical.  The one residual risk is libm ``sin``/``cos``, which
  is not required by either language spec to be correctly rounded; a 1-ulp
  difference could flip a 0.05-boundary rounding.  See python/README.md.
"""

from __future__ import annotations

import math
from typing import Any, Callable, Dict, List, Optional, Union

from . import coord as _coord

SCHEMA_VERSION = 1

BASE_R = 40  # base glyph half-extent
ANCHOR_R = 46  # compact attachment radius from center
MARKER_R = 64  # exploded socket-marker radius
ORBIT_R = 118  # exploded orbit-box center radius
BOX_HALF = 26  # exploded orbit-box half-size
CHILD_FACTOR = 0.5  # per-depth shrink
COMPACT_MOD_SCALE = 0.5
EXPLODED_MOD_SCALE = 1.4
DIAC_RING_COMPACT = 18
DIAC_RING_EXPLODED = 36
COMPACT_ADVANCE = 130  # glyph-to-glyph advance, compact
EXPLODED_ADVANCE = 400  # glyph-to-glyph advance, exploded
PAD = 18

# --------------------------------------------------------------------------
# util.js -- deterministic helpers.
# --------------------------------------------------------------------------


def js_round(x: float) -> int:
    """JS ``Math.round``: the integer closest to ``x``, ties toward
    +Infinity.  ``x - floor(x)`` is exact for |x| < 2**52 (both operands are
    representable and the fractional part needs <= 53 bits), so the
    comparison against 0.5 is exact."""
    f = math.floor(x)
    diff = x - f
    if diff > 0.5:
        return f + 1
    if diff < 0.5:
        return f
    return f + 1  # tie: toward +Infinity


def _intify(v: float) -> Union[int, float]:
    """Normalize integral floats (incl. -0.0) to int so JSON/string output
    matches JS number formatting (``40`` not ``40.0``)."""
    return int(v) if float(v).is_integer() else v


def r1(n: Union[int, float]) -> Union[int, float]:
    """Round to 0.1 exactly like JS ``r1``: ``Math.round(n * 10) / 10`` with
    ``-0`` normalized."""
    return _intify(js_round(n * 10) / 10)


def _scale3(s: Union[int, float]) -> Union[int, float]:
    """JS ``Math.round(scale * 1000) / 1000``."""
    return _intify(js_round(s * 1000) / 1000)


def js_num(v: Union[int, float]) -> str:
    """Stringify a finite number the way a JS template literal would.
    (Values here are small; the JS switch to exponential notation at 1e21 /
    below 1e-6 is out of range by construction.)"""
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise TypeError(f"expected a number, got {v!r}")
    if isinstance(v, int):
        return str(v)
    if v.is_integer():
        return str(int(v))
    return repr(v)


def _imul_u32(a: int, b: int) -> int:
    """Unsigned 32-bit low word of ``a * b`` -- JS ``Math.imul(a, b) >>> 0``.
    (Math.imul itself returns the signed low word; util.js always reapplies
    ``>>> 0``, so unsigned semantics hold.)"""
    return ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF


def hash32(n: int) -> int:
    """32-bit avalanche hash, identical to util.js.  Inputs are masked to 32
    bits first, matching JS ToUint32 coercion for the integer seeds used by
    the registry (exact for |n| < 2**53)."""
    x = (int(n) & 0xFFFFFFFF) ^ 0x9E3779B9
    x = _imul_u32(x ^ (x >> 16), 0x045D9F3B)
    x = _imul_u32(x ^ (x >> 16), 0x045D9F3B)
    return (x ^ (x >> 16)) & 0xFFFFFFFF


def rng(seed: int) -> Callable[[], float]:
    """Deterministic LCG PRNG in [0, 1): ``s = (s*1664525 + 1013904223) mod
    2**32; return s / 2**32``.  Division by 2**32 is exact in binary floating
    point, so the stream matches JS bit-for-bit."""
    s = int(seed) & 0xFFFFFFFF

    def rand() -> float:
        nonlocal s
        s = (s * 1664525 + 1013904223) & 0xFFFFFFFF
        return s / 4294967296

    return rand


# --------------------------------------------------------------------------
# registry.js -- seed enum + geometry registry (schema v1 stand-in).
# --------------------------------------------------------------------------

SOCKETS = (
    {"id": 0, "name": "upper", "angle": -90},
    {"id": 1, "name": "upper_right", "angle": -45},
    {"id": 2, "name": "right", "angle": 0},
    {"id": 3, "name": "lower_right", "angle": 45},
    {"id": 4, "name": "lower", "angle": 90},
    {"id": 5, "name": "lower_left", "angle": 135},
    {"id": 6, "name": "left", "angle": 180},
    {"id": 7, "name": "upper_left", "angle": -135},
)

SOCKET_COUNT = len(SOCKETS)


def socket_by_id(socket_id: int) -> Dict[str, Any]:
    return SOCKETS[((socket_id % SOCKET_COUNT) + SOCKET_COUNT) % SOCKET_COUNT]


def orientation_degrees(orientation_id: int) -> int:
    return (((orientation_id % 4) + 4) % 4) * 90


def _n(x: Union[int, float]) -> str:
    """``${r1(x)}`` -- round to 0.1 and stringify JS-style."""
    return js_num(r1(x))


def ring_points(rand: Callable[[], float], k: int, radius: float) -> List[List[float]]:
    pts = []
    for i in range(k):
        a = -math.pi / 2 + (i / k) * 2 * math.pi + (rand() - 0.5) * 0.9
        d = radius * (0.55 + 0.45 * rand())
        pts.append([math.cos(a) * d, math.sin(a) * d])
    return pts


def polyline(pts: List[List[float]], rand: Callable[[], float], wobble: float) -> str:
    d = f"M {_n(pts[0][0])} {_n(pts[0][1])}"
    for i in range(1, len(pts)):
        if i % 2 == 1:
            # rand() call order matches JS: mx first, then my.
            mx = (pts[i - 1][0] + pts[i][0]) / 2 + (rand() - 0.5) * wobble
            my = (pts[i - 1][1] + pts[i][1]) / 2 + (rand() - 0.5) * wobble
            d += f" Q {_n(mx)} {_n(my)} {_n(pts[i][0])} {_n(pts[i][1])}"
        else:
            d += f" L {_n(pts[i][0])} {_n(pts[i][1])}"
    return d


def base_path(base_id: int) -> str:
    """Base glyph stroke path, centered on (0,0), extent ~ +-40.
    Seed namespace 0x10000+id."""
    rand = rng(hash32(0x10000 + base_id))
    k = 4 + math.floor(rand() * 3)
    d = polyline(ring_points(rand, k, 34), rand, 26)
    tilt = (rand() - 0.5) * 0.45
    sx = math.cos(tilt) * 34
    sy = math.sin(tilt) * 34
    d += f" M {_n(-sx)} {_n(-sy)} L {_n(sx)} {_n(sy)}"
    return d


def modifier_path(shape_id: int) -> str:
    """Modifier stroke path, centered on (0,0), extent ~ +-16.
    Seed namespace 0x20000+id."""
    rand = rng(hash32(0x20000 + shape_id))
    k = 3 + math.floor(rand() * 2)
    return polyline(ring_points(rand, k, 15), rand, 12)


def diacritic_path(diacritic_id: int) -> str:
    """Diacritic mark, centered on (0,0), extent ~ +-5.  Four families
    (dot, bar, chevron, arc); seed namespace 0x30000+id."""
    family = hash32(0x30000 + diacritic_id) % 4
    if family == 0:
        return "M -3 0 A 3 3 0 1 0 3 0 A 3 3 0 1 0 -3 0"
    if family == 1:
        return "M -5 0 L 5 0"
    if family == 2:
        return "M -5 3 L 0 -4 L 5 3"
    return "M -5 2 Q 0 -6 5 2"


def diacritic_rotation(diacritic_id: int) -> int:
    """Deterministic rotation (multiples of 45 degrees).  Seed namespace
    0x40000+id."""
    return (hash32(0x40000 + diacritic_id) % 8) * 45


# --------------------------------------------------------------------------
# scene.js -- the compiler proper.
# --------------------------------------------------------------------------


def _rad(deg: Union[int, float]) -> float:
    return deg * math.pi / 180


def _placement(tx, ty, rotate=0, scale=1, visible=True) -> Dict[str, Any]:
    return {
        "translate": [r1(tx), r1(ty)],
        "rotate": r1(rotate),
        "scale": _scale3(scale),
        "visible": visible,
    }


def _hidden() -> Dict[str, Any]:
    return _placement(0, 0, 0, 1, False)


def _circle_path(cx, cy, r) -> str:
    x0, x1 = _n(cx - r), _n(cx + r)
    y, rr = _n(cy), _n(r)
    return f"M {x0} {y} A {rr} {rr} 0 1 0 {x1} {y} A {rr} {rr} 0 1 0 {x0} {y}"


def _rect_path(cx, cy, h) -> str:
    return f"M {_n(cx - h)} {_n(cy - h)} H {_n(cx + h)} V {_n(cy + h)} H {_n(cx - h)} Z"


class _Bounds:
    def __init__(self) -> None:
        self.min_x = math.inf
        self.min_y = math.inf
        self.max_x = -math.inf
        self.max_y = -math.inf

    def extend(self, x, y, r) -> None:
        self.min_x = min(self.min_x, x - r)
        self.min_y = min(self.min_y, y - r)
        self.max_x = max(self.max_x, x + r)
        self.max_y = max(self.max_y, y + r)

    def view_box(self, pad) -> list:
        if not math.isfinite(self.min_x):
            return [-60, -60, 120, 120]
        return [
            r1(self.min_x - pad),
            r1(self.min_y - pad),
            r1(self.max_x - self.min_x + 2 * pad),
            r1(self.max_y - self.min_y + 2 * pad),
        ]


def compile_scene(
    value: Union[str, list, "_coord.Word"],
    latinized: Optional[str] = None,
    integer: Optional[str] = None,
) -> Dict[str, Any]:
    """Compile a coordinate (Word, wire array, or JSON string) into a render
    model ``{schema, latinized, integer, coordinate, viewBox, nodes[]}``.

    ``latinized``/``integer`` are codec-provided facts: the scene compiler
    never computes them.  JS leaves absent options ``undefined`` (dropped by
    ``JSON.stringify``); here they are ``None`` -- consumers must treat
    missing and null alike.
    """
    word = _coord.as_word(value)
    wire = _coord.word_to_wire(word)
    nodes: List[Dict[str, Any]] = []
    bounds = _Bounds()

    for gi, glyph in enumerate(word.glyphs):
        gid = f"g{gi}"
        c_compact = [gi * COMPACT_ADVANCE, 0]
        c_exploded = [gi * EXPLODED_ADVANCE, 0]
        orient_deg = orientation_degrees(glyph.orientation)

        nodes.append(
            {
                "id": gid,
                "kind": "base",
                "path": base_path(glyph.base),
                "compact": _placement(c_compact[0], c_compact[1], orient_deg, 1),
                "exploded": _placement(c_exploded[0], c_exploded[1], orient_deg, 1),
            }
        )
        bounds.extend(c_compact[0], c_compact[1], BASE_R + 8)
        bounds.extend(c_exploded[0], c_exploded[1], BASE_R + 8)

        # Canonical sockets are all occupied (empties are omitted from the
        # tuple), mirroring JS `if (sock.modifier)`.
        for sock in glyph.sockets:
            _emit_socket(nodes, bounds, gid, sock, c_compact, c_exploded, orient_deg, 0)

    return {
        "schema": f"ithkuil-coordinate/{SCHEMA_VERSION}",
        "latinized": latinized,
        "integer": integer,
        "coordinate": wire,
        "viewBox": bounds.view_box(PAD),
        "nodes": nodes,
    }


def _emit_socket(nodes, bounds, parent_id, sock, c_compact, c_exploded, frame_deg, depth) -> None:
    sdef = socket_by_id(sock.socket_id)
    angle = sdef["angle"] + frame_deg
    dx = math.cos(_rad(angle))
    dy = math.sin(_rad(angle))
    k = CHILD_FACTOR ** depth
    prefix = f"{parent_id}.s{sock.socket_id}"

    anchor = [c_compact[0] + dx * ANCHOR_R * k, c_compact[1] + dy * ANCHOR_R * k]
    marker = [c_exploded[0] + dx * MARKER_R * k, c_exploded[1] + dy * MARKER_R * k]
    orbit = [c_exploded[0] + dx * ORBIT_R * k, c_exploded[1] + dy * ORBIT_R * k]
    box_h = BOX_HALF * k

    # 1. radial connector: exact center -> orbit box
    nodes.append(
        {
            "id": f"{prefix}.link",
            "parentId": parent_id,
            "kind": "connector",
            "path": f"M {_n(c_exploded[0])} {_n(c_exploded[1])} L {_n(orbit[0])} {_n(orbit[1])}",
            "compact": _hidden(),
            "exploded": _placement(0, 0),
        }
    )

    # 2. socket indicator circle + orbit box outline
    nodes.append(
        {
            "id": f"{prefix}.marker",
            "parentId": parent_id,
            "kind": "socket-marker",
            "path": _circle_path(marker[0], marker[1], max(2.5, 4 * k))
            + " "
            + _rect_path(orbit[0], orbit[1], box_h),
            "compact": _hidden(),
            "exploded": _placement(0, 0),
            "socket": {
                "id": sock.socket_id,
                "name": sdef["name"],
                "occupied": True,
                "anchor": [r1(anchor[0]), r1(anchor[1])],
                "orbitCenter": [r1(orbit[0]), r1(orbit[1])],
            },
        }
    )

    # 3. the modifier itself -- same node, two projections
    m = sock.modifier
    mod_deg = orientation_degrees(m.orientation) + frame_deg
    mod_id = f"{prefix}.mod"
    nodes.append(
        {
            "id": mod_id,
            "parentId": parent_id,
            "kind": "modifier",
            "path": modifier_path(m.shape),
            "compact": _placement(anchor[0], anchor[1], mod_deg, COMPACT_MOD_SCALE * k),
            "exploded": _placement(orbit[0], orbit[1], mod_deg, EXPLODED_MOD_SCALE * k),
        }
    )
    bounds.extend(anchor[0], anchor[1], (16 + DIAC_RING_COMPACT) * k + 8)
    bounds.extend(orbit[0], orbit[1], box_h + DIAC_RING_EXPLODED * k + 10)
    bounds.extend(marker[0], marker[1], 6)

    # 4. diacritics orbit the modifier's own local center in fixed 45deg slots
    for j, diac in enumerate(m.diacritics):
        slot = _rad(-90 + j * 45 + mod_deg)
        sx = math.cos(slot)
        sy = math.sin(slot)
        rot = diacritic_rotation(diac)
        nodes.append(
            {
                "id": f"{mod_id}.d{j}",
                "parentId": mod_id,
                "kind": "diacritic",
                "path": diacritic_path(diac),
                "compact": _placement(
                    anchor[0] + sx * DIAC_RING_COMPACT * k,
                    anchor[1] + sy * DIAC_RING_COMPACT * k,
                    rot,
                    max(0.5, 0.8 * k),
                ),
                "exploded": _placement(
                    orbit[0] + sx * DIAC_RING_EXPLODED * k,
                    orbit[1] + sy * DIAC_RING_EXPLODED * k,
                    rot,
                    max(0.5, k),
                ),
            }
        )

    # 5. recurse: the modifier's own sockets orbit ITS center
    for child in m.sockets:
        _emit_socket(nodes, bounds, mod_id, child, anchor, orbit, mod_deg, depth + 1)
