#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate one filled-hue UML/diagram node-type SVG icon per ElementKind.

Design language (matches the renderer + design-conventions.md):
  * Each icon IS the node's notation silhouette, filled in its KindInfo.Hue.
  * A darker outline of the same hue frames the shape (reads on light + dark).
  * Interior notation details (compartment lines, tabs, corner glyphs, guillemet
    stereotypes) are drawn in white on saturated/dark fills, dark ink on light fills.
  * viewBox 0 0 64 64, ~7px safe padding. Transparent background.

Output: <repo>/projects/therobotdrafts/Assets/Icons/Nodes/<Kind>.svg  (+ contact sheet + README)
"""
import os, math, colorsys

OUT = os.path.join(os.path.dirname(__file__), "out_nodes")  # overridden by --dest at bottom

# ----------------------------------------------------------------------------- colors
def hx(c):
    c = c.lstrip('#')
    if len(c) == 3:
        c = ''.join(ch * 2 for ch in c)
    return tuple(int(c[i:i+2], 16) for i in (0, 2, 4))

def rgb(t):
    return '#%02X%02X%02X' % tuple(max(0, min(255, int(round(v)))) for v in t)

def mix(a, b, t):
    a, b = hx(a), hx(b)
    return rgb(tuple(a[i] + (b[i] - a[i]) * t for i in range(3)))

def lum(c):
    r, g, b = [v / 255 for v in hx(c)]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def shade(c, f):
    return rgb(tuple(v * f for v in hx(c)))

class Ctx:
    def __init__(self, hue):
        self.hue = hue
        self.light = lum(hue) > 0.62               # a pale fill (note, sticky, ports…)
        # outline: pull the hue toward a deep neutral so every icon has a crisp edge
        self.line = mix(hue, '#1b2230', 0.46 if not self.light else 0.60)
        # interior detail ink: white on saturated fills, near-black on pale fills
        self.det = mix(hue, '#0d1116', 0.80) if self.light else '#FFFFFF'
        self.det2 = mix(self.det, hue, 0.30)       # secondary detail
        self.fillsoft = mix(hue, '#FFFFFF', 0.16)  # faint highlight tint

# ----------------------------------------------------------------------------- svg prims
SW = 2.0     # outline stroke
DW = 1.5     # detail stroke

def _sp(pts):
    return ' '.join('%.2f,%.2f' % (x, y) for x, y in pts)

def rect(x, y, w, h, fill, stroke=None, sw=SW, rx=0, dash=None, op=1):
    a = f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}"'
    if rx: a += f' rx="{rx:.2f}"'
    a += f' fill="{fill}"' if fill else ' fill="none"'
    if op != 1: a += f' fill-opacity="{op}"'
    if stroke: a += f' stroke="{stroke}" stroke-width="{sw}"'
    if dash: a += f' stroke-dasharray="{dash}"'
    return a + ' stroke-linejoin="round"/>'

def circ(cx, cy, r, fill, stroke=None, sw=SW, dash=None):
    a = f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r:.2f}"'
    a += f' fill="{fill}"' if fill else ' fill="none"'
    if stroke: a += f' stroke="{stroke}" stroke-width="{sw}"'
    if dash: a += f' stroke-dasharray="{dash}"'
    return a + '/>'

def ell(cx, cy, rx, ry, fill, stroke=None, sw=SW, dash=None):
    a = f'<ellipse cx="{cx:.2f}" cy="{cy:.2f}" rx="{rx:.2f}" ry="{ry:.2f}"'
    a += f' fill="{fill}"' if fill else ' fill="none"'
    if stroke: a += f' stroke="{stroke}" stroke-width="{sw}"'
    if dash: a += f' stroke-dasharray="{dash}"'
    return a + '/>'

def poly(pts, fill, stroke=None, sw=SW, dash=None, closed=True):
    tag = 'polygon' if closed else 'polyline'
    a = f'<{tag} points="{_sp(pts)}"'
    a += f' fill="{fill}"' if fill else ' fill="none"'
    if stroke: a += f' stroke="{stroke}" stroke-width="{sw}"'
    if dash: a += f' stroke-dasharray="{dash}"'
    return a + ' stroke-linejoin="round" stroke-linecap="round"/>'

def line(x1, y1, x2, y2, stroke, sw=DW, dash=None, cap='round'):
    a = f'<line x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}" stroke="{stroke}" stroke-width="{sw}"'
    if dash: a += f' stroke-dasharray="{dash}"'
    return a + f' stroke-linecap="{cap}"/>'

def path(d, fill, stroke=None, sw=SW, dash=None):
    a = f'<path d="{d}"'
    a += f' fill="{fill}"' if fill else ' fill="none"'
    if stroke: a += f' stroke="{stroke}" stroke-width="{sw}"'
    if dash: a += f' stroke-dasharray="{dash}"'
    return a + ' stroke-linejoin="round" stroke-linecap="round"/>'

def txt(x, y, s, size, fill, anchor='middle', weight='700', italic=False):
    st = ' font-style="italic"' if italic else ''
    return (f'<text x="{x:.2f}" y="{y:.2f}" font-family="Helvetica,Arial,sans-serif" '
            f'font-size="{size}" font-weight="{weight}"{st} fill="{fill}" '
            f'text-anchor="{anchor}" dominant-baseline="central">{s}</text>')

# ----------------------------------------------------------------------------- shared building blocks
def namebar(cx, y, w, ct, sw=2.6):
    """A short bold 'name' bar (stands in for the element name)."""
    return line(cx - w / 2, y, cx + w / 2, y, ct.det, sw)

def rows(x, y, w, n, ct, gap=6, sw=DW, frac=0.72):
    return [line(x, y + i * gap, x + w * frac, y + i * gap, ct.det, sw) for i in range(n)]

def stereo(cx, y, s, ct, size=8.5):
    return txt(cx, y, f'«{s}»', size, ct.det, weight='600')

def corner_box(x, y, w, h, ct):
    """faint inset panel used behind a corner glyph (keeps it legible on the fill)."""
    return rect(x, y, w, h, ct.fillsoft, None, op=0.0)

# ============================================================================= DRAWERS
def d_class(ct, stereo_lbl=None, comp=(2, 2), rounded=0, underline=False, valueticks=False):
    x, y, w, h = 12, 11, 40, 42
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=rounded)]
    head = 14
    out.append(line(x, y + head, x + w, y + head, ct.line, SW))
    if stereo_lbl:
        out.append(stereo(x + w / 2, y + 6.5, stereo_lbl, ct, 8))
        out.append(namebar(x + w / 2, y + head - 3.5, w * 0.5, ct, 2.4))
    else:
        out.append(namebar(x + w / 2, y + head / 2 + 0.5, w * 0.55, ct, 3.0))
    if underline:
        out.append(line(x + w / 2 - w * 0.28, y + head / 2 + 4, x + w / 2 + w * 0.28, y + head / 2 + 4, ct.det, 1.4))
    c1 = y + head + (h - head) / 2
    out.append(line(x, c1, x + w, c1, ct.line, SW))
    out += rows(x + 6, y + head + 8, w - 12, comp[0], ct)
    if valueticks:
        for i in range(comp[1]):
            out.append(circ(x + 8, c1 + 8 + i * 7, 1.4, ct.det, None))
        out += [line(x + 12, c1 + 8 + i * 7, x + w - 6, c1 + 8 + i * 7, ct.det, DW) for i in range(comp[1])]
    else:
        out += rows(x + 6, c1 + 8, w - 12, comp[1], ct)
    return out

def d_titled(ct, stereo_lbl=None, rounded=3, dashed=False, glyph=None):
    x, y, w, h = 11, 16, 42, 32
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=rounded, dash='4 3' if dashed else None)]
    if stereo_lbl:
        out.append(stereo(x + w / 2, y + h / 2 - 5, stereo_lbl, ct, 8))
        out.append(namebar(x + w / 2, y + h / 2 + 6, w * 0.5, ct, 2.6))
    else:
        out.append(namebar(x + w / 2, y + h / 2, w * 0.5, ct, 3.0))
    if glyph:
        out += glyph(x + w - 13, y + 4, ct)
    return out

def d_rounded(ct, rake=False, pill=False):
    x, y, w, h = 11, 18, 42, 28
    r = h / 2 if pill else 9
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=r), namebar(x + w / 2, y + h / 2, w * 0.42, ct, 3.0)]
    if rake:  # call-behaviour rake glyph, bottom-centre
        rx, ry = x + w / 2, y + h - 8
        out.append(line(rx, ry, rx, ry + 6, ct.det, 1.6))
        out += [line(rx - 4 + i * 4, ry, rx - 4 + i * 4, ry + 6, ct.det, 1.6) for i in range(3)]
        out.append(line(rx - 4, ry, rx + 4, ry, ct.det, 1.6))
    return out

def d_ellipse(ct, dashed=False):
    return [ell(32, 32, 24, 16, ct.hue, ct.line, dash='4 3' if dashed else None),
            namebar(32, 32, 22, ct, 3.0)]

def d_disc(ct, r=11):
    return [circ(32, 32, r, ct.hue, ct.line)]

def d_final(ct):
    return [circ(32, 32, 13, 'none', ct.line, 2.2), circ(32, 32, 7, ct.hue, None)]

def d_history(ct):
    return [circ(32, 32, 12, ct.hue, ct.line), txt(32, 32.5, 'H', 13, ct.det, weight='700')]

def d_terminate(ct):
    return [line(23, 23, 41, 41, ct.hue, 4.2), line(41, 23, 23, 41, ct.hue, 4.2)]

def d_flowfinal(ct):
    return [circ(32, 32, 13, 'none', ct.line, 2.2),
            line(26, 26, 38, 38, ct.line, 2.6), line(38, 26, 26, 38, ct.line, 2.6)]

def d_forkjoin(ct, vertical=False):
    if vertical:
        return [rect(29, 12, 6, 40, ct.hue, ct.line, rx=1)]
    return [rect(12, 29, 40, 6, ct.hue, ct.line, rx=1)]

def d_note(ct, lines=2, fold=13, stereo_lbl=None):
    x, y, w, h = 14, 12, 36, 40
    f = fold
    d = (f'M{x},{y} H{x+w-f} L{x+w},{y+f} V{y+h} H{x} Z')
    out = [path(d, ct.hue, ct.line, SW)]
    out.append(path(f'M{x+w-f},{y} V{y+f} H{x+w}', mix(ct.hue, '#000', 0.18), ct.line, SW))
    yy = y + f + 6
    if stereo_lbl:
        out.append(stereo(x + (w) / 2 - 2, yy, stereo_lbl, ct, 7)); yy += 8
    out += [line(x + 5, yy + i * 6, x + w - 6, yy + i * 6, ct.det, DW) for i in range(lines)]
    return out

def d_folder(ct, dashed=False, stereo_lbl=None):
    x, y, w, h = 12, 14, 40, 36
    tabw, tabh = 17, 8
    out = [rect(x, y, tabw, tabh, ct.hue, ct.line, rx=1.5),
           rect(x, y + tabh, w, h - tabh, ct.hue, ct.line, rx=1.5, dash='4 3' if dashed else None)]
    if stereo_lbl:
        out.append(stereo(x + w / 2, y + tabh + (h - tabh) / 2 - 4, stereo_lbl, ct, 8))
    return out

def d_component(ct):
    x, y, w, h = 16, 15, 34, 34
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=2)]
    for ty in (y + 7, y + 20):
        out.append(rect(x - 6, ty, 12, 8, ct.hue, ct.line, sw=1.6))
    return out

def d_cube(ct, rack=False, rounded_front=False):
    x, y, w, h, dp = 14, 18, 34, 30, 9
    front = [(x, y + dp), (x + w - dp, y + dp), (x + w - dp, y + h), (x, y + h)]
    out = [poly([(x, y + dp), (x + dp, y), (x + w, y), (x + w - dp, y + dp)], shade(ct.hue, 1.12), ct.line),
           poly([(x + w - dp, y + dp), (x + w, y), (x + w, y + h - dp), (x + w - dp, y + h)], shade(ct.hue, 0.82), ct.line),
           rect(x, y + dp, w - dp, h - dp, ct.hue, ct.line, rx=2 if rounded_front else 0)]
    if rack:
        for i in range(3):
            out.append(line(x + 4, y + dp + 7 + i * 6, x + w - dp - 4, y + dp + 7 + i * 6, ct.det, 1.6))
    return out

def d_cylinder(ct):
    x, w = 20, 24
    yt, yb, e = 16, 48, 5
    d = (f'M{x},{yt} V{yb} A{w/2},{e} 0 0 0 {x+w},{yb} V{yt}')
    out = [path(d, ct.hue, ct.line, SW),
           ell(x + w / 2, yt, w / 2, e, ct.hue, ct.line),
           path(f'M{x},{yt} A{w/2},{e} 0 0 0 {x+w},{yt}', 'none', ct.line, 1.4)]
    return out

def d_cloud(ct):
    d = ('M22,40 a8,8 0 0 1 1,-15 a10,10 0 0 1 19,-3 a8,8 0 0 1 2,18 Z')
    return [path('M20,42 '
                 'a9,9 0 0 1 0.5,-17 '
                 'a11,11 0 0 1 20,-4 '
                 'a9,9 0 0 1 3,20 Z', ct.hue, ct.line, SW)]

def d_actor(ct, filled=False):
    cx = 32
    out = []
    if filled:  # C4 person: filled head + rounded torso
        out.append(circ(cx, 20, 7, ct.hue, ct.line))
        out.append(path('M20,50 v-4 a12,10 0 0 1 24,0 v4 Z', ct.hue, ct.line, SW))
    else:  # UML stick actor
        out.append(circ(cx, 18, 6, ct.hue, ct.line))
        out.append(line(cx, 24, cx, 40, ct.hue, 2.6))
        out.append(line(20, 30, 44, 30, ct.hue, 2.6))
        out.append(line(cx, 40, 22, 52, ct.hue, 2.6))
        out.append(line(cx, 40, 42, 52, ct.hue, 2.6))
    return out

def d_stadium(ct):
    return [rect(11, 20, 42, 24, ct.hue, ct.line, rx=12), namebar(32, 32, 20, ct, 3.0)]

def d_parallelogram(ct):
    return [poly([(19, 46), (26, 18), (53, 18), (46, 46)], ct.hue, ct.line), namebar(36, 32, 18, ct, 3.0)]

def d_document(ct):
    x, y, w = 12, 15, 40
    d = (f'M{x},{y} H{x+w} V44 q{-w/4},-6 {-w/2},0 t{-w/2},0 Z')
    return [path(d, ct.hue, ct.line, SW), namebar(x + w / 2, y + 12, 20, ct, 2.6)]

def d_datastore_dfd(ct):
    x, y, w, h = 12, 20, 42, 24
    out = [line(x, y, x + w, y, ct.line, SW), line(x, y + h, x + w, y + h, ct.line, SW),
           line(x, y, x, y + h, ct.line, SW),
           rect(x, y, 8, h, mix(ct.hue, '#000', 0.15), None),
           rect(x, y, w, h, ct.hue, None, op=0.0)]
    # fill the open box lightly so it reads as a filled node
    out.insert(0, rect(x, y, w, h, ct.hue, None))
    out.append(line(x + 8, y, x + 8, y + h, ct.line, 1.4))
    out.append(namebar(x + w / 2 + 4, y + h / 2, 20, ct, 2.6))
    return out

def d_external_entity(ct, double=True):
    out = [rect(16, 16, 32, 32, ct.hue, ct.line, rx=1)]
    if double:
        out.append(line(20, 16, 20, 48, ct.det, 1.4))
        out.append(line(16, 20, 48, 20, ct.det, 1.4))
    out.append(namebar(34, 34, 16, ct, 2.6))
    return out

def d_firewall(ct):
    x, y, w, h = 12, 18, 40, 28
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=1)]
    for i in range(1, 4):
        out.append(line(x, y + i * h / 4, x + w, y + i * h / 4, ct.det, 1.4))
    # staggered brick verticals
    for r in range(4):
        yy = y + r * h / 4
        offs = [x + w / 4, x + 3 * w / 4] if r % 2 == 0 else [x + w / 2, x + w]
        for ox in offs:
            if x < ox < x + w:
                out.append(line(ox, yy, ox, yy + h / 4, ct.det, 1.4))
    return out

def d_monitor(ct):
    out = [rect(14, 16, 36, 24, ct.hue, ct.line, rx=2),
           rect(18, 20, 28, 16, ct.fillsoft, None, op=0.35),
           line(32, 40, 32, 46, ct.line, 2.4), line(24, 47, 40, 47, ct.line, 2.6)]
    return out

def d_mindnode(ct):
    return [rect(12, 20, 40, 24, ct.hue, ct.line, rx=12), namebar(32, 32, 22, ct, 3.0)]

def d_swlane(ct, header_left=True, band=10):
    x, y, w, h = 11, 14, 42, 36
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=2)]
    if header_left:
        out.append(rect(x, y, band, h, mix(ct.hue, '#000', 0.16), ct.line))
        out.append(line(x + band, y, x + band, y + h, ct.line, 1.4))
    return out

def d_pool(ct):
    out = d_swlane(ct, band=11)
    out.append(line(22, 32, 22, 32, ct.det, 0))  # noop keep
    out.append(line(11, 32, 53, 32, ct.line, 1.2, dash='3 3'))
    return out

# ---- corner glyphs (for ArchiMate/strategy boxes): drawn ~12px at (gx,gy) ----
def g_actor(gx, gy, ct):
    cx = gx + 6
    return [circ(cx, gy + 2.5, 2.4, 'none', ct.det, 1.4),
            line(cx, gy + 5, cx, gy + 10, ct.det, 1.4),
            line(cx - 3.5, gy + 7, cx + 3.5, gy + 7, ct.det, 1.4),
            line(cx, gy + 10, cx - 3, gy + 13, ct.det, 1.4),
            line(cx, gy + 10, cx + 3, gy + 13, ct.det, 1.4)]

def g_arrow(gx, gy, ct):  # process chevron
    return [poly([(gx, gy + 2), (gx + 7, gy + 2), (gx + 12, gy + 6.5), (gx + 7, gy + 11), (gx, gy + 11),
                  (gx + 4, gy + 6.5)], 'none', ct.det, 1.4)]

def g_component(gx, gy, ct):
    return [rect(gx + 2, gy + 1, 9, 10, 'none', ct.det, 1.3),
            rect(gx, gy + 3, 4, 2.6, 'none', ct.det, 1.2),
            rect(gx, gy + 7, 4, 2.6, 'none', ct.det, 1.2)]

def g_box3d(gx, gy, ct):
    return [poly([(gx, gy + 4), (gx + 3, gy + 1), (gx + 11, gy + 1), (gx + 8, gy + 4)], 'none', ct.det, 1.2),
            poly([(gx + 8, gy + 4), (gx + 11, gy + 1), (gx + 11, gy + 9), (gx + 8, gy + 12)], 'none', ct.det, 1.2),
            rect(gx, gy + 4, 8, 8, 'none', ct.det, 1.2)]

def g_device(gx, gy, ct):
    return [rect(gx, gy + 2, 12, 8, 'none', ct.det, 1.3, rx=1.5),
            line(gx + 3, gy + 12, gx + 9, gy + 12, ct.det, 1.6)]

def g_target(gx, gy, ct):
    cx, cy = gx + 6, gy + 6
    return [circ(cx, cy, 5.5, 'none', ct.det, 1.3), circ(cx, cy, 2.4, ct.det, None)]

def g_gear(gx, gy, ct):
    cx, cy = gx + 6, gy + 6
    return [circ(cx, cy, 3.4, 'none', ct.det, 1.3)] + \
           [line(cx + 4.6 * math.cos(a), cy + 4.6 * math.sin(a),
                 cx + 6.4 * math.cos(a), cy + 6.4 * math.sin(a), ct.det, 1.3)
            for a in [i * math.pi / 3 for i in range(6)]]

def g_flag(gx, gy, ct):
    return [line(gx + 1, gy + 1, gx + 1, gy + 12, ct.det, 1.5),
            poly([(gx + 1, gy + 1), (gx + 10, gy + 3), (gx + 1, gy + 6)], 'none', ct.det, 1.3)]

def g_doc(gx, gy, ct):
    return [path(f'M{gx+1},{gy+1} h7 l3,3 v8 h-10 Z', 'none', ct.det, 1.2),
            poly([(gx + 8, gy + 1), (gx + 8, gy + 4), (gx + 11, gy + 4)], 'none', ct.det, 1.2)]

def g_req(gx, gy, ct):
    return [rect(gx, gy + 1, 12, 11, 'none', ct.det, 1.2, rx=1),
            line(gx + 2.5, gy + 4.5, gx + 9, gy + 4.5, ct.det, 1.1),
            line(gx + 2.5, gy + 7.5, gx + 9, gy + 7.5, ct.det, 1.1)]

def g_layers(gx, gy, ct):
    return [poly([(gx + 6, gy + 1), (gx + 12, gy + 4), (gx + 6, gy + 7), (gx, gy + 4)], 'none', ct.det, 1.2),
            poly([(gx, gy + 8), (gx + 6, gy + 11), (gx + 12, gy + 8)], 'none', ct.det, 1.2, closed=False)]

def g_gap(gx, gy, ct):
    return [path(f'M{gx+2},{gy+6} a4,4 0 0 1 8,0', 'none', ct.det, 1.3),
            line(gx + 2, gy + 9, gx + 4.5, gy + 9, ct.det, 1.4),
            line(gx + 7.5, gy + 9, gx + 10, gy + 9, ct.det, 1.4)]

def g_principle(gx, gy, ct):
    cx, cy = gx + 6, gy + 6
    return [circ(cx, cy, 5.5, 'none', ct.det, 1.3), txt(cx, cy + 0.5, '!', 8, ct.det, weight='800')]

def g_capability(gx, gy, ct):
    return [rect(gx, gy + 1, 12, 11, 'none', ct.det, 1.3, rx=2.5),
            rect(gx + 3, gy + 4, 6, 5, ct.det, None)]

def g_service(gx, gy, ct):
    return [rect(gx, gy + 3, 12, 7, 'none', ct.det, 1.3, rx=3.5)]

# ---- one-off complex nodes ----
def d_lifeline(ct):
    out = [rect(20, 12, 24, 16, ct.hue, ct.line, rx=1), namebar(32, 20, 14, ct, 2.4),
           line(32, 28, 32, 54, ct.line, 1.6, dash='4 4')]
    return out

def d_activation(ct):
    return [line(32, 12, 32, 54, ct.line, 1.4, dash='4 4'),
            rect(28, 20, 8, 26, ct.hue, ct.line, rx=1)]

def d_frame(ct, tag='sd'):
    x, y, w, h = 12, 14, 40, 36
    tw, th = 16, 11
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=1)]
    out.append(path(f'M{x},{y} h{tw} l0,{th-4} l-4,4 h{-(tw-4)} Z', mix(ct.hue, '#000', 0.16), ct.line, 1.6))
    out.append(txt(x + tw / 2 - 1, y + th / 2, tag, 7.5, ct.det, weight='700'))
    return out

def d_boundary(ct):
    x, y, w, h = 12, 15, 40, 34
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=3, op=0.9)]
    out.append(rect(x, y, w, h, 'none', ct.line, SW, rx=3))
    out.append(line(x + 8, y, x + 8, y + h, ct.line, 1.4))
    out.append(namebar(x + (w + 8) / 2 + 2, y + 7, 18, ct, 2.4))
    return out

def d_port_bar(ct, filled=True, nested=False):
    out = [line(11, 32, 53, 32, ct.line, 1.4)]
    out.append(rect(27, 27, 10, 10, ct.hue if filled else ct.fillsoft, ct.line, rx=1))
    if nested:
        out.append(rect(30, 30, 4, 4, ct.det, None))
    return out

def d_constraint(ct):
    x, y, w, h = 11, 16, 42, 32
    return [rect(x, y, w, h, ct.hue, ct.line, rx=8),
            stereo(x + w / 2, y + 9, 'constraint', ct, 7),
            txt(x + w / 2, y + 21, '{ x=y }', 8, ct.det, weight='600')]

def d_bkm(ct):  # DMN business knowledge: clipped top corners
    x, y, w, h, c = 12, 16, 40, 30, 8
    d = f'M{x+c},{y} H{x+w-c} L{x+w},{y+c} V{y+h} H{x} V{y+c} Z'
    return [path(d, ct.hue, ct.line, SW), namebar(x + w / 2, y + h / 2 + 2, 18, ct, 2.8)]

def d_ksource(ct):  # DMN knowledge source: wavy bottom
    x, y, w = 12, 15, 40
    d = f'M{x},{y} H{x+w} V40 q{-w/6},6 {-w/3},0 t{-w/3},0 t{-w/3},0 Z'
    return [path(d, ct.hue, ct.line, SW), namebar(x + w / 2, y + 12, 18, ct, 2.8)]

def d_decision_service(ct):
    x, y, w, h = 11, 16, 42, 32
    return [rect(x, y, w, h, ct.hue, ct.line, rx=9),
            line(x, y + 13, x + w, y + 13, ct.line, 1.6),
            namebar(x + w / 2, y + 6.5, 16, ct, 2.4)]

def d_annotation(ct):
    x, y, h = 22, 16, 32
    out = [path(f'M{x+6},{y} H{x} V{y+h} H{x+6}', 'none', ct.line, SW)]
    out += [line(x + 10, y + 8 + i * 7, x + 40, y + 8 + i * 7, ct.det, DW) for i in range(3)]
    return out

def d_bpmn_event(ct):
    return [circ(32, 32, 14, ct.hue, ct.line), circ(32, 32, 10.5, 'none', ct.line, 1.4)]

def d_bpmn_gateway(ct):
    out = [poly([(32, 14), (50, 32), (32, 50), (14, 32)], ct.hue, ct.line)]
    out += [line(26, 26, 38, 38, ct.det, 2.2), line(38, 26, 26, 38, ct.det, 2.2)]
    return out

def d_bpmn_activity(ct):
    x, y, w, h = 12, 20, 40, 24
    return [rect(x, y, w, h, ct.hue, ct.line, rx=5),
            rect(x + w / 2 - 4, y + h - 9, 8, 6, 'none', ct.det, 1.3),
            line(x + w / 2, y + h - 8, x + w / 2, y + h - 4, ct.det, 1.2),
            line(x + w / 2 - 2, y + h - 6, x + w / 2 + 2, y + h - 6, ct.det, 1.2)]

def d_bpmn_dataobj(ct):
    x, y, w, h, f = 20, 12, 24, 40, 9
    d = f'M{x},{y} H{x+w-f} L{x+w},{y+f} V{y+h} H{x} Z'
    return [path(d, ct.hue, ct.line, SW), path(f'M{x+w-f},{y} V{y+f} H{x+w}', mix(ct.hue, '#000', 0.18), ct.line, 1.6)]

def d_choreography(ct):
    x, y, w, h = 12, 16, 40, 32
    return [rect(x, y, w, h, ct.hue, ct.line, rx=5),
            rect(x, y, w, 7, mix(ct.hue, '#000', 0.14), ct.line, sw=1.4, rx=5),
            rect(x, y + h - 7, w, 7, mix(ct.hue, '#000', 0.14), ct.line, sw=1.4, rx=5)]

def d_hexagon(ct, stereo_lbl=None):
    pts = [(20, 16), (44, 16), (52, 32), (44, 48), (20, 48), (12, 32)]
    out = [poly(pts, ct.hue, ct.line)]
    if stereo_lbl:
        out.append(stereo(32, 30, stereo_lbl, ct, 7))
    out.append(namebar(32, 36 if stereo_lbl else 32, 18, ct, 2.6))
    return out

def d_chevron(ct, notch=False):
    x, y, w, h = 12, 20, 40, 24
    tip = 10
    if notch:
        pts = [(x, y), (x + w - tip, y), (x + w, y + h / 2), (x + w - tip, y + h),
               (x, y + h), (x + tip, y + h / 2)]
    else:
        pts = [(x, y), (x + w - tip, y), (x + w, y + h / 2), (x + w - tip, y + h), (x, y + h)]
    return [poly(pts, ct.hue, ct.line), namebar(x + w / 2 - 2, y + h / 2, 16, ct, 2.6)]

def d_quadrant(ct):
    x, y, w, h = 13, 16, 38, 32
    return [rect(x, y, w, h, ct.hue, ct.line, rx=2),
            line(x + w / 2, y, x + w / 2, y + h, ct.det, 1.4),
            line(x, y + h / 2, x + w, y + h / 2, ct.det, 1.4)]

def d_orgunit(ct):
    out = [line(32, 12, 32, 18, ct.line, 1.4),
           rect(22, 18, 20, 14, ct.hue, ct.line, rx=2),
           line(24, 40, 40, 40, ct.line, 1.4), line(24, 40, 24, 46, ct.line, 1.4),
           line(40, 40, 40, 46, ct.line, 1.4),
           line(32, 32, 32, 40, ct.line, 1.4)]
    return out

def d_heatmap(ct):
    x, y, w, h = 14, 16, 36, 32
    bands = ['#F2C94C', '#F2994A', '#EB5757']
    out = []
    for i, cbase in enumerate(bands):
        cc = mix(ct.hue, cbase, 0.5)
        out.append(rect(x, y + i * h / 3, w, h / 3, cc, None))
    out.append(rect(x, y, w, h, 'none', ct.line, SW, rx=2))
    return out

def d_dtree(ct):
    out = [poly([(32, 12), (42, 22), (32, 32), (22, 22)], ct.hue, ct.line),
           line(27, 27, 18, 40, ct.line, 1.6), line(37, 27, 46, 40, ct.line, 1.6),
           circ(18, 44, 4, ct.hue, ct.line), circ(46, 44, 4, ct.hue, ct.line)]
    return out

def d_brickblock(ct):
    x, y, w, h = 13, 16, 38, 32
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=1)]
    out.append(line(x, y + h / 2, x + w, y + h / 2, ct.det, 1.4))
    out.append(line(x + w / 2, y, x + w / 2, y + h / 2, ct.det, 1.4))
    out.append(line(x + w / 4, y + h / 2, x + w / 4, y + h, ct.det, 1.4))
    out.append(line(x + 3 * w / 4, y + h / 2, x + 3 * w / 4, y + h, ct.det, 1.4))
    return out

def d_admphase(ct):
    cx, cy, r = 32, 32, 15
    out = [circ(cx, cy, r, ct.hue, ct.line), circ(cx, cy, 5, ct.fillsoft, ct.line, 1.4)]
    # highlight one wedge
    out.append(path(f'M{cx},{cy} L{cx},{cy-r} A{r},{r} 0 0 1 {cx+r*math.sin(math.radians(60)):.2f},{cy-r*math.cos(math.radians(60)):.2f} Z',
                    mix(ct.hue, '#fff', 0.35), ct.line, 1.4))
    for a in range(0, 360, 60):
        out.append(line(cx, cy, cx + r * math.sin(math.radians(a)), cy - r * math.cos(math.radians(a)), ct.line, 1.1))
    return out

def d_zachman(ct):
    x, y, w, h = 13, 16, 38, 32
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=1)]
    for i in (1, 2):
        out.append(line(x + i * w / 3, y, x + i * w / 3, y + h, ct.det, 1.3))
    out.append(line(x, y + h / 2, x + w, y + h / 2, ct.det, 1.3))
    out.append(rect(x + w / 3, y, w / 3, h / 2, ct.det, None, op=0.35))
    return out

# ---- wireframe widget glyphs (concrete UI controls) ----
def wf_frame(ct, title=True):
    x, y, w, h = 11, 13, 42, 38
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=2)]
    out.append(rect(x, y, w, 8, mix(ct.hue, '#000', 0.16), ct.line, sw=1.4))
    for i in range(3):
        out.append(circ(x + 5 + i * 4, y + 4, 1.3, ct.det, None))
    return out

def wf_panel(ct):
    return [rect(11, 15, 42, 34, 'none', ct.line, SW, rx=2, dash='5 3'),
            rect(11, 15, 42, 34, ct.hue, None, op=0.18)]

def wf_button(ct):
    return [rect(14, 24, 36, 16, ct.hue, ct.line, rx=4), namebar(32, 32, 14, ct, 2.6)]

def wf_label(ct):
    return [line(16, 26, 48, 26, ct.det, 2.6), line(16, 33, 40, 33, ct.det, 2.6)]

def wf_link(ct):
    return [txt(32, 30, 'link', 12, ct.det, weight='700'), line(20, 38, 44, 38, ct.det, 1.6)]

def wf_textfield(ct):
    out = [rect(13, 26, 38, 13, ct.hue, ct.line, rx=2), line(18, 32.5, 18, 36, ct.det, 1.6),
           line(20, 33, 40, 33, ct.det, 1.4)]
    return out

def wf_textarea(ct):
    x, y, w, h = 13, 18, 38, 28
    return [rect(x, y, w, h, ct.hue, ct.line, rx=2)] + \
           [line(x + 4, y + 6 + i * 6, x + w - 5, y + 6 + i * 6, ct.det, 1.4) for i in range(3)]

def wf_password(ct):
    out = [rect(13, 26, 38, 13, ct.hue, ct.line, rx=2)]
    out += [circ(20 + i * 5, 32.5, 1.8, ct.det, None) for i in range(5)]
    return out

def wf_checkbox(ct):
    return [rect(15, 27, 12, 12, ct.hue, ct.line, rx=2),
            poly([(18, 33), (21, 36), (25, 29)], 'none', ct.det, 2.0, closed=False),
            line(31, 33, 48, 33, ct.det, 2.4)]

def wf_radio(ct):
    return [circ(21, 33, 6.5, ct.hue, ct.line), circ(21, 33, 2.6, ct.det, None),
            line(31, 33, 48, 33, ct.det, 2.4)]

def wf_dropdown(ct):
    return [rect(13, 26, 38, 13, ct.hue, ct.line, rx=2),
            line(18, 33, 34, 33, ct.det, 1.6),
            poly([(42, 30), (48, 30), (45, 35)], ct.det, None)]

def wf_list(ct):
    x, y, w, h = 15, 17, 34, 30
    return [rect(x, y, w, h, ct.hue, ct.line, rx=2)] + \
           [line(x + 4, y + 6 + i * 7, x + w - 5, y + 6 + i * 7, ct.det, 1.6) for i in range(4)]

def wf_table(ct):
    x, y, w, h = 12, 17, 40, 30
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=1.5)]
    out.append(rect(x, y, w, 8, mix(ct.hue, '#000', 0.14), ct.line, sw=1.3))
    for i in (1, 2): out.append(line(x, y + 8 + i * 7, x + w, y + 8 + i * 7, ct.det, 1.3))
    for i in (1, 2): out.append(line(x + i * w / 3, y, x + i * w / 3, y + h, ct.det, 1.3))
    return out

def wf_tree(ct):
    out = []
    xs = [(18, 20), (26, 27), (26, 34), (18, 41)]
    for x, y in xs:
        out.append(line(16, y, x, y, ct.det, 1.4))
        out.append(rect(x, y - 2.5, 22 if x == 18 else 18, 5, ct.hue, ct.line, sw=1.4, rx=1))
    out.insert(0, line(16, 18, 16, 41, ct.det, 1.4))
    return out

def wf_image(ct):
    x, y, w, h = 14, 18, 36, 28
    return [rect(x, y, w, h, ct.hue, ct.line, rx=2),
            circ(x + 9, y + 8, 3, ct.det, None),
            poly([(x + 3, y + h - 4), (x + 15, y + 11), (x + 24, y + h - 4)], 'none', ct.det, 1.6, closed=False),
            poly([(x + 18, y + h - 4), (x + 27, y + 14), (x + w - 3, y + h - 4)], 'none', ct.det, 1.6, closed=False)]

def wf_tabs(ct):
    x, y, w = 12, 17, 40
    out = [rect(x, y + 8, w, 26, ct.hue, ct.line, rx=2)]
    for i in range(3):
        cc = ct.hue if i == 0 else mix(ct.hue, '#000', 0.18)
        out.append(rect(x + i * 13, y, 13, 10, cc, ct.line, sw=1.4, rx=2))
    return out

def wf_menu(ct):
    x, y, w = 12, 24, 40
    out = [rect(x, y, w, 12, ct.hue, ct.line, rx=1.5)]
    for i in range(3):
        out.append(line(x + 5 + i * 12, y + 6, x + 12 + i * 12, y + 6, ct.det, 1.6))
    return out

def wf_card(ct):
    x, y, w, h = 15, 16, 34, 32
    return [rect(x, y, w, h, ct.hue, ct.line, rx=3),
            rect(x + 4, y + 4, w - 8, 8, ct.fillsoft, None, op=0.4),
            line(x + 4, y + 18, x + w - 6, y + 18, ct.det, 1.4),
            line(x + 4, y + 23, x + w - 10, y + 23, ct.det, 1.4)]

def wf_separator(ct):
    return [line(12, 32, 52, 32, ct.hue, 3.4)]

def wf_progress(ct):
    return [rect(13, 28, 38, 9, ct.hue, ct.line, rx=4.5),
            rect(13, 28, 22, 9, ct.det, None, rx=4.5)]

def wf_slider(ct):
    return [line(14, 33, 50, 33, ct.line, 2.4), circ(30, 33, 5.5, ct.hue, ct.line)]

def wf_breadcrumb(ct):
    out = []
    for i, s in enumerate(('a', 'b', 'c')):
        out.append(txt(18 + i * 14, 32, s, 10, ct.det, weight='700'))
        if i < 2:
            out.append(txt(25 + i * 14, 32, '›', 11, ct.det2, weight='700'))
    return out

def wf_toolbar(ct):
    x, y, w = 12, 25, 40
    out = [rect(x, y, w, 14, ct.hue, ct.line, rx=2)]
    for i in range(4):
        out.append(rect(x + 4 + i * 9, y + 4, 6, 6, ct.det, None, op=0.9))
    return out

def wf_generic(ct):
    return [rect(14, 18, 36, 28, ct.hue, ct.line, rx=3, dash='1 0'),
            rect(20, 24, 24, 16, 'none', ct.det, 1.4, dash='3 2')]

def d_task(ct):
    x, y, w, h = 13, 18, 38, 26
    return [rect(x, y, w, h, ct.hue, ct.line, rx=3),
            rect(x + 4, y + 5, 8, 8, ct.fillsoft, ct.line, sw=1.3, rx=1.5),
            poly([(x + 6, y + 9), (x + 8, y + 11), (x + 11, y + 6.5)], 'none', ct.det, 1.6, closed=False),
            line(x + 16, y + 9, x + w - 6, y + 9, ct.det, 1.6),
            rect(x + 4, y + 17, w - 8, 4, ct.det, None, op=0.85, rx=2)]

def d_kanban(ct):
    x, y, w, h = 16, 13, 32, 38
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=2),
           rect(x, y, w, 8, mix(ct.hue, '#000', 0.16), ct.line, sw=1.4)]
    out.append(rect(x + 4, y + 12, w - 8, 9, ct.fillsoft, ct.line, sw=1.3, rx=1.5))
    out.append(rect(x + 4, y + 24, w - 8, 9, ct.fillsoft, ct.line, sw=1.3, rx=1.5))
    return out

def d_wb_frame(ct):
    # rough hand-drawn rectangle
    d = 'M13,17 L50,15 L52,48 L15,50 Z'
    return [path(d, ct.hue, ct.line, 2.2)]

def d_wb_card(ct):
    x, y, w, h = 14, 16, 36, 32
    return [rect(x, y, w, h, ct.hue, ct.line, rx=2),
            line(x + 4, y + 8, x + w - 5, y + 8, ct.det, 1.6),
            line(x + 4, y + 15, x + w - 8, y + 15, ct.det, 1.4)]

def d_wb_text(ct):
    return [txt(32, 26, 'T', 20, ct.det, weight='800'), line(18, 40, 46, 40, ct.det2, 1.6)]

# ============================================================================= registry
# (hue, family, label, drawer-callable)
def K(drawer):  # wrap to make lambda-friendly
    return drawer

HUE = {
 'Package':'#6E7B8B','Class':'#0072B2','Interface':'#56B4E9','Enum':'#E69F00','Struct':'#009E73',
 'Function':'#2CA02C','Field':'#BCBD22','Note':'#F2E2A0','Actor':'#6B5B95','UseCase':'#4E9BC4',
 'State':'#5AB28A','StateStart':'#2A2D34','StateEnd':'#2A2D34','External':'#999999','DataType':'#7FA6B0',
 'PrimitiveType':'#9AA7B0','ObjectInstance':'#0072B2','Boundary':'#8893A0','Decision':'#E69F00',
 'ForkJoin':'#2A2D34','Junction':'#2A2D34','History':'#5AB28A','Terminate':'#2A2D34','Activity':'#4FA3A0',
 'FlowFinal':'#2A2D34','Component':'#5B8AC4','Artifact':'#B0A878','DeploymentNode':'#6E7B8B',
 'PackageNode':'#6E7B8B','Part':'#7E8AA2','Port':'#C7CDD6','Collaboration':'#B9A6C8','Lifeline':'#5B8AC4',
 'Activation':'#DDE3EA','Frame':'#8893A0','Metaclass':'#8FA8B8','Stereotype':'#C8A2C8','Profile':'#8893A0',
 'TimingLifeline':'#5B8AC4','CallActivity':'#4FA3A0','EntityTable':'#2C7FB8','Person':'#7B6FB0',
 'SoftwareSystem':'#1F6FB2','Container':'#438DD5','FlowProcess':'#5B8AC4','FlowTerminator':'#5AB28A',
 'FlowIO':'#E69F00','FlowDocument':'#B0A878','DataStore':'#7FA6B0','ExternalEntity':'#8893A0',
 'Server':'#6E7B8B','Database':'#4F86C6','Cloud':'#56B4E9','Client':'#9AA7B0','Firewall':'#C44E52',
 'MindNode':'#4FA3A0','Screen':'#8893A0','UiWidget':'#C7CDD6','Panel':'#7E8AA2','Button':'#4FA3A0',
 'Label':'#9AA7B0','Link':'#0284C7','TextField':'#7FA6B0','TextArea':'#7FA6B0','Password':'#7FA6B0',
 'Checkbox':'#9AA7B0','Radio':'#9AA7B0','Dropdown':'#7FA6B0','List':'#9AA7B0','Table':'#7FA6B0',
 'Tree':'#9AA7B0','Image':'#B0A878','Tabs':'#9AA7B0','Menu':'#9AA7B0','Card':'#C7CDD6','Separator':'#C7CDD6',
 'Progress':'#5AB28A','Slider':'#9AA7B0','Breadcrumb':'#9AA7B0','Toolbar':'#9AA7B0','Task':'#2CA02C',
 'KanbanColumn':'#7E8AA2','WhiteboardFrame':'#7E8AA2','WhiteboardSticky':'#F2E2A0','WhiteboardCard':'#DDE3EA',
 'WhiteboardText':'#F8FAFC','WhiteboardCircle':'#56B4E9','WhiteboardDiamond':'#E69F00','AsyncSend':'#4FA3A0',
 'AsyncReceive':'#4FA3A0','SysmlBlock':'#3F83B5','SysmlValueType':'#6BA6B8','SysmlConstraintBlock':'#8AA6C1',
 'SysmlRequirement':'#E7C65B','SysmlProxyPort':'#C7CDD6','SysmlFullPort':'#9AA7B0','SysmlParameter':'#7FA6B0',
 'BpmnEvent':'#5AB28A','BpmnActivity':'#56B4E9','BpmnGateway':'#E69F00','BpmnDataObject':'#B0A878',
 'BpmnDataStore':'#7FA6B0','BpmnPool':'#8893A0','BpmnLane':'#A8B0BC','BpmnChoreographyTask':'#8FA8B8',
 'BpmnConversation':'#B9A6C8','DmnDecision':'#E69F00','DmnInputData':'#56B4E9','DmnBusinessKnowledge':'#7B6FB0',
 'DmnKnowledgeSource':'#B0A878','DmnDecisionService':'#4FA3A0','DmnTextAnnotation':'#F2E2A0',
 'ArchiBusinessActor':'#E7C65B','ArchiBusinessProcess':'#E69F00','ArchiApplicationComponent':'#56B4E9',
 'ArchiApplicationService':'#4F86C6','ArchiDataObject':'#7FA6B0','ArchiNode':'#5AB28A','ArchiDevice':'#6E7B8B',
 'ArchiSystemSoftware':'#009E73','ArchiTechnologyService':'#4FA3A0','ArchiCapability':'#7B6FB0',
 'ArchiOutcome':'#B9A6C8','ArchiRequirement':'#C8A2C8','ArchiPrinciple':'#9B8AC4','ArchiWorkPackage':'#D08A3C',
 'ArchiDeliverable':'#B0A878','ArchiPlateau':'#7E8AA2','ArchiGap':'#C44E52','BusinessCapability':'#7B6FB0',
 'ValueStream':'#4FA3A0','ValueChainActivity':'#E69F00','StrategyObjective':'#C8A2C8',
 'BalancedScorecardPerspective':'#8893A0','OrgUnit':'#7E8AA2','HeatMapItem':'#C44E52','DecisionTreeNode':'#E69F00',
 'UafOperationalNode':'#3F83B5','UafService':'#4FA3A0','UafResource':'#6E7B8B','UafCapability':'#7B6FB0',
 'TogafArchitectureBuildingBlock':'#5B8AC4','TogafArchitecturePhase':'#B0A878','ZachmanCell':'#8893A0',
}

# family + label + drawer for each kind
def AR(g):  # ArchiMate box with corner glyph
    return lambda ct: d_titled(ct, glyph=g)

SPEC = {
 # ---- Class / classifiers ----
 'Package':        ('Class','Package', lambda ct: d_folder(ct)),
 'Class':          ('Class','Class', lambda ct: d_class(ct)),
 'Interface':      ('Class','Interface', lambda ct: [circ(32,7.5,3.2,'none',ct.line,1.8), line(32,10.7,32,11,ct.line,1.8)]+d_class(ct,'interface',comp=(2,1))),
 'Enum':           ('Class','Enum', lambda ct: d_class(ct,'enum',comp=(0,3),valueticks=True)),
 'Struct':         ('Class','Struct', lambda ct: d_class(ct,'struct',comp=(3,0))),
 'Function':       ('Class','Function', lambda ct: [circ(32,32,12,ct.hue,ct.line), txt(32,32.5,'ƒ',15,ct.det,weight='700')]),
 'Field':          ('Class','Field', lambda ct: [rect(16,27,32,10,ct.hue,ct.line,rx=2), circ(21,32,2.2,ct.det,None), line(26,32,44,32,ct.det,2.0)]),
 'DataType':       ('Class','Data Type', lambda ct: d_class(ct,'dataType',comp=(2,1))),
 'PrimitiveType':  ('Class','Primitive', lambda ct: d_titled(ct,'primitive')),
 'ObjectInstance': ('Object','Object', lambda ct: d_class(ct,None,comp=(3,0),underline=True)),
 'EntityTable':    ('ERD','Table / Entity', lambda ct: d_entity(ct)),
 'External':       ('Class','External', lambda ct: d_titled(ct,'external',dashed=True)),
 'Metaclass':      ('Profile','Metaclass', lambda ct: d_titled(ct,'metaclass')),
 'Stereotype':     ('Profile','Stereotype', lambda ct: d_titled(ct,'stereotype')),
 'Profile':        ('Profile','Profile', lambda ct: d_folder(ct,stereo_lbl='profile')),

 # ---- Use case ----
 'Actor':          ('Use Case','Actor', lambda ct: d_actor(ct)),
 'UseCase':        ('Use Case','Use Case', lambda ct: d_ellipse(ct)),
 'Boundary':       ('Use Case','System Boundary', lambda ct: d_boundary(ct)),

 # ---- State machine / activity ----
 'State':          ('State','State', lambda ct: d_rounded(ct)),
 'StateStart':     ('State','Initial', lambda ct: d_disc(ct)),
 'StateEnd':       ('State','Final', lambda ct: d_final(ct)),
 'Decision':       ('State','Decision / Merge', lambda ct: [poly([(32,15),(49,32),(32,49),(15,32)],ct.hue,ct.line)]),
 'ForkJoin':       ('State','Fork / Join', lambda ct: d_forkjoin(ct)),
 'Junction':       ('State','Junction', lambda ct: d_disc(ct,r=6)),
 'History':        ('State','History', lambda ct: d_history(ct)),
 'Terminate':      ('State','Terminate', lambda ct: d_terminate(ct)),
 'Activity':       ('Activity','Action', lambda ct: d_rounded(ct,pill=True)),
 'CallActivity':   ('Activity','Activity (call)', lambda ct: d_rounded(ct,rake=True)),
 'FlowFinal':      ('Activity','Flow Final', lambda ct: d_flowfinal(ct)),
 'AsyncSend':      ('Activity','Send Signal', lambda ct: [poly([(14,20),(40,20),(50,32),(40,44),(14,44)],ct.hue,ct.line), namebar(29,32,14,ct,2.6)]),
 'AsyncReceive':   ('Activity','Receive Event', lambda ct: [poly([(14,20),(50,20),(50,44),(14,44),(24,32)],ct.hue,ct.line), namebar(35,32,14,ct,2.6)]),

 # ---- Component / deployment ----
 'Component':      ('Component','Component', lambda ct: d_component(ct)),
 'Artifact':       ('Deployment','Artifact', lambda ct: d_note(ct,lines=2,fold=10,stereo_lbl='artifact')),
 'DeploymentNode': ('Deployment','Node / Device', lambda ct: d_cube(ct)),
 'PackageNode':    ('Package','Package', lambda ct: d_folder(ct)),

 # ---- Composite structure ----
 'Part':           ('Composite','Part', lambda ct: [rect(12,17,40,30,ct.hue,ct.line,rx=1), rect(48,26,6,6,ct.hue,ct.line,sw=1.4), namebar(31,32,18,ct,2.8)]),
 'Port':           ('Composite','Port', lambda ct: d_port_bar(ct,filled=True)),
 'Collaboration':  ('Composite','Collaboration', lambda ct: d_ellipse(ct,dashed=True)),

 # ---- Sequence / interaction ----
 'Lifeline':       ('Sequence','Lifeline', lambda ct: d_lifeline(ct)),
 'Activation':     ('Sequence','Activation', lambda ct: d_activation(ct)),
 'Frame':          ('Sequence','Fragment', lambda ct: d_frame(ct)),
 'TimingLifeline': ('Timing','Timing Lifeline', lambda ct: d_timing(ct)),

 # ---- C4 ----
 'Person':         ('C4','Person', lambda ct: d_actor(ct,filled=True)),
 'SoftwareSystem': ('C4','Software System', lambda ct: [rect(11,17,42,30,ct.hue,ct.line,rx=3), namebar(32,28,22,ct,3.2), line(20,37,44,37,ct.det2,1.6)]),
 'Container':      ('C4','Container', lambda ct: [rect(12,18,40,28,ct.hue,ct.line,rx=6), namebar(32,29,20,ct,3.0), line(20,37,44,37,ct.det2,1.6)]),

 # ---- Flowchart ----
 'FlowProcess':    ('Flowchart','Process', lambda ct: [rect(12,20,40,24,ct.hue,ct.line,rx=1), namebar(32,32,20,ct,3.0)]),
 'FlowTerminator': ('Flowchart','Start / End', lambda ct: d_stadium(ct)),
 'FlowIO':         ('Flowchart','Input / Output', lambda ct: d_parallelogram(ct)),
 'FlowDocument':   ('Flowchart','Document', lambda ct: d_document(ct)),

 # ---- DFD ----
 'DataStore':      ('DFD','Data Store', lambda ct: d_datastore_dfd(ct)),
 'ExternalEntity': ('DFD','External Entity', lambda ct: d_external_entity(ct)),

 # ---- Infrastructure ----
 'Server':         ('Infra','Server / Host', lambda ct: d_cube(ct,rack=True)),
 'Database':       ('Infra','Database', lambda ct: d_cylinder(ct)),
 'Cloud':          ('Infra','Cloud / Service', lambda ct: d_cloud(ct)),
 'Client':         ('Infra','Client / Device', lambda ct: d_monitor(ct)),
 'Firewall':       ('Infra','Firewall', lambda ct: d_firewall(ct)),

 # ---- Mind map / notes ----
 'MindNode':       ('Mind Map','Topic', lambda ct: d_mindnode(ct)),
 'Note':           ('Notes','Note', lambda ct: d_note(ct)),

 # ---- Project ----
 'Task':           ('Project','Task', lambda ct: d_task(ct)),
 'KanbanColumn':   ('Project','Kanban Column', lambda ct: d_kanban(ct)),

 # ---- Whiteboard ----
 'WhiteboardFrame':  ('Whiteboard','Frame', lambda ct: d_wb_frame(ct)),
 'WhiteboardSticky': ('Whiteboard','Sticky Note', lambda ct: d_note(ct,lines=2,fold=11)),
 'WhiteboardCard':   ('Whiteboard','Card', lambda ct: d_wb_card(ct)),
 'WhiteboardText':   ('Whiteboard','Text', lambda ct: d_wb_text(ct)),
 'WhiteboardCircle': ('Whiteboard','Circle / Bubble', lambda ct: [circ(32,32,17,ct.hue,ct.line)]),
 'WhiteboardDiamond':('Whiteboard','Diamond', lambda ct: [poly([(32,14),(50,32),(32,50),(14,32)],ct.hue,ct.line)]),

 # ---- Wireframe / UI ----
 'Screen':    ('Wireframe','Screen', lambda ct: wf_frame(ct)),
 'Panel':     ('Wireframe','Panel', lambda ct: wf_panel(ct)),
 'UiWidget':  ('Wireframe','Widget (generic)', lambda ct: wf_generic(ct)),
 'Button':    ('Wireframe','Button', wf_button),
 'Label':     ('Wireframe','Label', wf_label),
 'Link':      ('Wireframe','Link', wf_link),
 'TextField': ('Wireframe','Text Field', wf_textfield),
 'TextArea':  ('Wireframe','Text Area', wf_textarea),
 'Password':  ('Wireframe','Password', wf_password),
 'Checkbox':  ('Wireframe','Checkbox', wf_checkbox),
 'Radio':     ('Wireframe','Radio', wf_radio),
 'Dropdown':  ('Wireframe','Dropdown', wf_dropdown),
 'List':      ('Wireframe','List', wf_list),
 'Table':     ('Wireframe','Table', wf_table),
 'Tree':      ('Wireframe','Tree', wf_tree),
 'Image':     ('Wireframe','Image', wf_image),
 'Tabs':      ('Wireframe','Tabs', wf_tabs),
 'Menu':      ('Wireframe','Menu', wf_menu),
 'Card':      ('Wireframe','Card', wf_card),
 'Separator': ('Wireframe','Separator', wf_separator),
 'Progress':  ('Wireframe','Progress', wf_progress),
 'Slider':    ('Wireframe','Slider', wf_slider),
 'Breadcrumb':('Wireframe','Breadcrumb', wf_breadcrumb),
 'Toolbar':   ('Wireframe','Toolbar', wf_toolbar),

 # ---- SysML ----
 'SysmlBlock':          ('SysML','Block', lambda ct: d_titled(ct,'block')),
 'SysmlValueType':      ('SysML','Value Type', lambda ct: d_titled(ct,'valueType')),
 'SysmlConstraintBlock':('SysML','Constraint Block', d_constraint),
 'SysmlRequirement':    ('SysML','Requirement', lambda ct: d_class(ct,'requirement',comp=(2,1))),
 'SysmlProxyPort':      ('SysML','Proxy Port', lambda ct: d_port_bar(ct,filled=False,nested=True)),
 'SysmlFullPort':       ('SysML','Full Port', lambda ct: d_port_bar(ct,filled=True)),
 'SysmlParameter':      ('SysML','Parameter', lambda ct: [rect(16,24,32,16,ct.hue,ct.line,rx=3), circ(23,32,2.4,ct.det,None), line(29,32,44,32,ct.det,2.0)]),

 # ---- BPMN ----
 'BpmnEvent':           ('BPMN','Event', d_bpmn_event),
 'BpmnActivity':        ('BPMN','Activity', d_bpmn_activity),
 'BpmnGateway':         ('BPMN','Gateway', d_bpmn_gateway),
 'BpmnDataObject':      ('BPMN','Data Object', d_bpmn_dataobj),
 'BpmnDataStore':       ('BPMN','Data Store', d_cylinder),
 'BpmnPool':            ('BPMN','Pool', d_pool),
 'BpmnLane':            ('BPMN','Lane', lambda ct: d_swlane(ct)),
 'BpmnChoreographyTask':('BPMN','Choreography', d_choreography),
 'BpmnConversation':    ('BPMN','Conversation', lambda ct: d_hexagon(ct)),

 # ---- DMN ----
 'DmnDecision':         ('DMN','Decision', lambda ct: [rect(12,19,40,26,ct.hue,ct.line,rx=1), namebar(32,32,20,ct,3.0)]),
 'DmnInputData':        ('DMN','Input Data', d_stadium),
 'DmnBusinessKnowledge':('DMN','Business Knowledge', d_bkm),
 'DmnKnowledgeSource':  ('DMN','Knowledge Source', d_ksource),
 'DmnDecisionService':  ('DMN','Decision Service', d_decision_service),
 'DmnTextAnnotation':   ('DMN','Annotation', d_annotation),

 # ---- ArchiMate ----
 'ArchiBusinessActor':      ('ArchiMate','Business Actor', AR(g_actor)),
 'ArchiBusinessProcess':    ('ArchiMate','Business Process', AR(g_arrow)),
 'ArchiApplicationComponent':('ArchiMate','App Component', AR(g_component)),
 'ArchiApplicationService': ('ArchiMate','App Service', lambda ct: d_rounded(ct,pill=True)),
 'ArchiDataObject':         ('ArchiMate','Data Object', lambda ct: [rect(12,16,40,32,ct.hue,ct.line,rx=1), rect(12,16,40,8,mix(ct.hue,'#000',0.14),ct.line,sw=1.4), namebar(32,36,20,ct,2.8)]),
 'ArchiNode':               ('ArchiMate','Node', AR(g_box3d)),
 'ArchiDevice':             ('ArchiMate','Device', AR(g_device)),
 'ArchiSystemSoftware':     ('ArchiMate','System Software', AR(g_gear)),
 'ArchiTechnologyService':  ('ArchiMate','Tech Service', lambda ct: d_rounded(ct,pill=True)),
 'ArchiCapability':         ('ArchiMate','Capability', AR(g_capability)),
 'ArchiOutcome':            ('ArchiMate','Outcome', AR(g_target)),
 'ArchiRequirement':        ('ArchiMate','Requirement', AR(g_req)),
 'ArchiPrinciple':          ('ArchiMate','Principle', AR(g_principle)),
 'ArchiWorkPackage':        ('ArchiMate','Work Package', AR(g_flag)),
 'ArchiDeliverable':        ('ArchiMate','Deliverable', lambda ct: [path('M12,16 H52 V40 q-10,6 -20,0 t-20,0 Z',ct.hue,ct.line,SW), namebar(32,26,20,ct,2.8)]),
 'ArchiPlateau':            ('ArchiMate','Plateau', AR(g_layers)),
 'ArchiGap':                ('ArchiMate','Gap', AR(g_gap)),

 # ---- Business strategy ----
 'BusinessCapability':          ('Strategy','Capability', AR(g_capability)),
 'ValueStream':                 ('Strategy','Value Stream', lambda ct: d_chevron(ct,notch=False)),
 'ValueChainActivity':          ('Strategy','Value Chain', lambda ct: d_chevron(ct,notch=True)),
 'StrategyObjective':           ('Strategy','Objective', AR(g_flag)),
 'BalancedScorecardPerspective':('Strategy','Scorecard Perspective', d_quadrant),
 'OrgUnit':                     ('Strategy','Org Unit', d_orgunit),
 'HeatMapItem':                 ('Strategy','Heat Map Item', d_heatmap),
 'DecisionTreeNode':            ('Strategy','Decision Tree Node', d_dtree),

 # ---- Enterprise frameworks ----
 'UafOperationalNode':          ('Enterprise','UAF Operational Node', lambda ct: d_hexagon(ct,'ON')),
 'UafService':                  ('Enterprise','UAF Service', lambda ct: d_rounded(ct,pill=True)),
 'UafResource':                 ('Enterprise','UAF Resource', lambda ct: d_cube(ct)),
 'UafCapability':               ('Enterprise','UAF Capability', AR(g_capability)),
 'TogafArchitectureBuildingBlock':('Enterprise','TOGAF ABB', d_brickblock),
 'TogafArchitecturePhase':      ('Enterprise','TOGAF ADM Phase', d_admphase),
 'ZachmanCell':                 ('Enterprise','Zachman Cell', d_zachman),
}

def d_entity(ct):
    x, y, w, h = 12, 12, 40, 40
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=2)]
    out.append(rect(x, y, w, 12, mix(ct.hue, '#000', 0.16), ct.line, sw=1.6))
    out.append(namebar(x + w / 2, y + 6, w * 0.5, ct, 2.8))
    # key row
    out.append(circ(x + 7, y + 20, 2.2, 'none', ct.det, 1.4))
    out.append(line(x + 5.4, y + 21.6, x + 8.6, y + 18.4, ct.det, 1.2))
    out.append(line(x + 12, y + 20, x + w - 6, y + 20, ct.det, DW))
    out += [line(x + 7, y + 20 + i * 7, x + w - 6, y + 20 + i * 7, ct.det, DW) for i in range(1, 4)]
    return out

def d_timing(ct):
    x, y, w, h = 12, 16, 40, 30
    out = [rect(x, y, w, h, ct.hue, ct.line, rx=1)]
    hi, lo = y + 7, y + h - 7
    pts = [(x + 3, lo), (x + 3, hi), (x + 15, hi), (x + 15, lo), (x + 27, lo), (x + 27, hi), (x + 37, hi)]
    out.append(poly(pts, None, ct.det, 2.0, closed=False))
    return out

# ============================================================================= emit
def wrap(kind, label, body):
    inner = '\n  '.join(body)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" '
            f'width="64" height="64" role="img" aria-label="{label}">\n'
            f'  <title>{label}</title>\n  {inner}\n</svg>\n')

def main(dest):
    nodes_dir = os.path.join(dest, 'Nodes')
    os.makedirs(nodes_dir, exist_ok=True)
    order = list(SPEC.keys())
    missing = [k for k in HUE if k not in SPEC]
    if missing:
        print('WARN: kinds without spec:', missing)
    cards = []
    fams = {}
    for kind in order:
        fam, label, drawer = SPEC[kind]
        hue = HUE[kind]
        ct = Ctx(hue)
        body = drawer(ct)
        svg = wrap(kind, label, body)
        with open(os.path.join(nodes_dir, kind + '.svg'), 'w') as f:
            f.write(svg)
        cards.append((kind, fam, label, hue))
        fams.setdefault(fam, []).append((kind, label, hue))
    # contact sheet
    sheet = ['<!doctype html><meta charset="utf-8"><title>Node icons</title>',
             '<style>body{background:#0f1116;color:#c9d1d9;font:13px/1.4 Helvetica,Arial;margin:24px}'
             'h2{color:#e6edf3;border-bottom:1px solid #30363d;padding-bottom:6px;margin-top:30px}'
             '.grid{display:flex;flex-wrap:wrap;gap:10px}'
             '.cell{width:104px;text-align:center;background:#161b22;border:1px solid #21262d;border-radius:8px;padding:8px 4px}'
             '.cell.light{background:#e9edf2}'
             'img{width:56px;height:56px}.n{font-size:11px;margin-top:4px;color:#9aa7b0;word-break:break-word}'
             '.toggle{position:fixed;top:10px;right:14px}</style>',
             '<h1>UML / diagram node icons — %d kinds</h1>' % len(order)]
    for fam, items in fams.items():
        sheet.append(f'<h2>{fam} <span style="color:#6e7681;font-weight:400">· {len(items)}</span></h2><div class="grid">')
        for kind, label, hue in items:
            sheet.append(f'<div class="cell"><img src="Nodes/{kind}.svg" alt="{label}"><div class="n">{label}<br><span style="color:#586069">{kind}</span></div></div>')
        sheet.append('</div>')
    with open(os.path.join(dest, '_contact-sheet.html'), 'w') as f:
        f.write('\n'.join(sheet))
    print(f'wrote {len(order)} svgs to {nodes_dir}')
    print('families:', {k: len(v) for k, v in fams.items()})
    return order, fams

if __name__ == '__main__':
    import sys
    dest = sys.argv[1] if len(sys.argv) > 1 else OUT
    main(dest)
