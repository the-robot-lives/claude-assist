"""Standalone SVG export with embedded coordinate metadata + exact recovery.

Byte-compatible port of ``web/src/metadata.js`` ``sceneToSVG`` /
``extractCoordinate``: same attribute set, same ``<metadata
id="ithkuil-coordinate">`` JSON block, so

    extract_coordinate(render(compile_scene(c))) == word_to_wire(c)

holds with no vision, OCR, or geometric inference.  Recognition of
UNANNOTATED glyphs is a deferred, separate subsystem -- deliberately not
implemented here.

Byte-parity notes:

* The metadata JSON uses ``json.dumps(..., separators=(",", ":"),
  ensure_ascii=False)`` and the fixed key order ``schema, latinized,
  integer, mode, coordinate`` to match JS ``JSON.stringify`` exactly
  (compact separators; insertion-ordered keys; non-ASCII text unescaped).
* ``&`` and ``<`` are then escaped as ``\\u0026`` / ``\\u003c``.  Both only
  ever occur inside JSON strings, so the escaped body is still valid JSON
  AND can never break strict XML parsing.
"""

from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from typing import Any, Dict, Optional

from .scene import js_num as _num

KIND_ATTRS = {
    "base": 'stroke-width="3"',
    "modifier": 'stroke-width="2.4"',
    "diacritic": 'stroke-width="2"',
    "connector": 'stroke-width="1" stroke-dasharray="4 3" opacity="0.65"',
    "socket-marker": 'stroke-width="1.25"',
}


def _esc(s: Any) -> str:
    """XML attribute/text escaping, replacement order matching metadata.js
    (& first so later entities are not double-escaped)."""
    return (
        str(s)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def render(model: Dict[str, Any], mode: str = "compact") -> str:
    """Render a scene model (from :func:`ithkuil.scene.compile_scene` or the
    Elixir codec) to a standalone SVG document string."""
    if mode not in ("compact", "exploded"):
        raise ValueError(f"unknown mode: {mode}")

    x, y, w, h = model["viewBox"]

    lines = []
    for node in model["nodes"]:
        p = node.get(mode)
        if not p or not p.get("visible") or not node.get("path"):
            continue
        t = (
            f"translate({_num(p['translate'][0])} {_num(p['translate'][1])})"
            f" rotate({_num(p['rotate'])}) scale({_num(p['scale'])})"
        )
        extra = KIND_ATTRS.get(node["kind"], "")
        lines.append(
            f'  <g data-node-id="{_esc(node["id"])}" data-kind="{_esc(node["kind"])}"'
            f' transform="{t}" {extra}><path d="{_esc(node["path"])}"/></g>'
        )
    body = "\n".join(lines)

    # Escape & and < as JSON \u escapes (both only ever occur inside JSON
    # strings) so the metadata body can never break strict XML parsing.
    meta = json.dumps(
        {
            "schema": model["schema"],
            "latinized": model.get("latinized"),
            "integer": model.get("integer"),
            "mode": mode,
            "coordinate": model["coordinate"],
        },
        separators=(",", ":"),
        ensure_ascii=False,
    ).replace("&", "\\u0026").replace("<", "\\u003c")

    integer = model.get("integer")
    integer_attr = f' data-ithkuil-integer="{_esc(integer)}"' if integer else ""
    latinized = model.get("latinized")
    title = f"  <title>{_esc(latinized)}</title>\n" if latinized else ""

    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{_num(x)} {_num(y)} {_num(w)} {_num(h)}"'
        f' data-ithkuil-schema="{_esc(model["schema"])}"{integer_attr}'
        f' fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">\n'
        f"{title}"
        f'  <metadata id="ithkuil-coordinate">{meta}</metadata>\n'
        f"{body}\n</svg>\n"
    )


def extract_metadata(svg_text: str) -> Optional[Dict[str, Any]]:
    """Full embedded metadata block ``{schema, latinized, integer, mode,
    coordinate}`` or ``None`` when absent/unparseable (mirrors JS
    ``extractMetadata``: any failure degrades to None, never raises)."""
    try:
        root = ET.fromstring(svg_text)
    except (ET.ParseError, ValueError, TypeError):
        return None
    chosen = None
    for elem in root.iter():
        if elem.tag.rpartition("}")[2] == "metadata":
            if elem.get("id") == "ithkuil-coordinate":
                chosen = elem
                break
            if chosen is None:
                chosen = elem  # fallback: first <metadata>
    if chosen is None or not chosen.text:
        return None
    try:
        parsed = json.loads(chosen.text)
    except json.JSONDecodeError:
        return None
    return parsed if isinstance(parsed, dict) else None


def extract_coordinate(svg_text: str) -> Optional[list]:
    """Exact tuple recovery from an SDK-generated SVG: the coordinate wire
    form, or ``None`` when the metadata was stripped (at which point the
    file is an ordinary unannotated drawing and belongs to the deferred
    recognition subsystem)."""
    meta = extract_metadata(svg_text)
    if isinstance(meta, dict) and isinstance(meta.get("coordinate"), list):
        return meta["coordinate"]
    return None
