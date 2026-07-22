# rackdiag — Server rack elevation generator from text

rackdiag renders datacenter rack elevations from a compact text grammar: you set the rack height in units (U) and list equipment by starting unit and height. It draws the numbered rack frame and places each item at its correct U position with proper multi-unit sizing. It is part of the *blockdiag family* (and ships inside the `nwdiag` package). Output is PNG, SVG, or PDF via a Python CLI.

**Current Version**: rackdiag 3.x (ships with nwdiag 3.0.0+)  **License**: Apache 2.0  **Runtime**: Python 3.7+ CLI (no browser)

## Official Resources & Documentation
- Home / docs: http://blockdiag.com/en/nwdiag/rackdiag-examples.html
- GitHub: https://github.com/blockdiag/nwdiag
- PyPI (bundled): https://pypi.org/project/nwdiag/
- Sphinx extension: https://pypi.org/project/sphinxcontrib-nwdiag/

## Installation & Setup
```bash
pip install nwdiag                     # provides the rackdiag command (+ nwdiag, packetdiag)
pip install "nwdiag[pdf]"              # reportlab-backed PDF output
pip install sphinxcontrib-nwdiag       # Sphinx directives (rackdiag directive included)
```
CLI rendering (command is `rackdiag`):
```bash
rackdiag rack.diag                     # -> rack.png
rackdiag rack.diag -T svg -o rack.svg  # SVG
rackdiag rack.diag -T pdf -o rack.pdf  # PDF (needs [pdf] extra)
rackdiag -f /path/Font.ttf rack.diag   # embed a TTF for non-ASCII labels
```

## Shared blockdiag-family Grammar
rackdiag wraps its body in `rackdiag { … }`. These constructs are common to the whole family; rackdiag-specific unit syntax follows.

**Comments**: `// line` and `# line`.

**Diagram-level attributes**: `default_node_color`, `default_group_color`, `default_fontsize`, `default_textcolor`, `node_width`, `node_height`, `span_width`, `span_height` (many family defaults exist, but rackdiag layout is driven mainly by the U grid — see below).

**Item attributes** — `unit: Name [attr = value];`: `color`, `textcolor`, `fontsize`, plus the rack-specific `NU` height token inside `[ ]`. Colors accept CSS names or `#rrggbb`; `style = dashed/dotted` and per-item `description` are supported.

**Classes** bundle reusable attributes: `class net [color = "#cfe2f3"];` then apply with `[class = "net"]`.

## Core Syntax / rackdiag Units
The body opens with the rack height (`NU;`), then lists equipment as `startUnit: Label [heightU];`. Omitting `[NU]` means a 1U item. Numbering runs bottom-up by default; `ascending;` flips it to top-down.

```rackdiag
rackdiag {
  16U;                       // 16-unit rack frame
  1: UPS [2U];               // occupies units 1–2
  3: Server [1U];
  4: DB Server [1U];
  5: Switch;                 // no [NU] => 1U
  8: Storage Array [3U];     // units 8–10
  16: Patch Panel [1U];      // top unit
}
```

**Rack height & numbering direction**:
```rackdiag
rackdiag {
  42U;                       // full-height rack
  ascending;                 // number top→bottom instead of the default bottom→up
  1: Blank Panel [1U];
  2: Firewall [1U];
  3: Core Switch [2U];
}
```

**Multi-unit items** use the `[NU]` height token; the starting unit plus `N` must fit the frame:
```rackdiag
rackdiag {
  24U;
  1: PDU [1U];
  2: UPS [4U];               // units 2–5
  6: Blade Chassis [6U];     // units 6–11
  12: Storage [2U];
}
```

**Colors per unit** — style any item inline:
```rackdiag
rackdiag {
  12U;
  1: UPS [2U]        [color = "#cccccc"];
  3: Web Server      [color = "#d9ead3"];
  4: Web Server      [color = "#d9ead3"];
  6: Database [2U]   [color = "#fce5cd"];
  9: Switch          [color = "#cfe2f3"];
}
```
(Two bracket groups are allowed: `[NU]` for height, `[attr = …]` for styling. You may also merge them: `6: Database [2U, color = "#fce5cd"];`.)

**Empty / blank units**: simply leave gaps in the unit numbers — unlisted units render as empty slots. Use a `Blank Panel` item when you want a labeled filler.

## Diagram / Output Types — describing racks & rack groups
A single `rackdiag { }` describes one rack. To draw **multiple racks side by side**, wrap each in a `rack { }` block. The outer `rackdiag` can carry a `description` for the row.

```rackdiag
rackdiag {
  // Row of two racks
  rack {
    12U;
    description = "Rack A — Compute";
    1: UPS [2U];
    3: Server [1U];
    4: Server [1U];
    6: Switch [1U];
  }
  rack {
    12U;
    description = "Rack B — Storage";
    1: UPS [2U];
    3: Storage Head [1U];
    4: Disk Shelf [3U];
    8: Switch [1U];
  }
}
```
Each `rack { }` gets its own U-numbered frame and independent height.

## How-To

### How to add colors, styling & themes
Set diagram defaults, then color items by role, factoring repeats into a `class`.
```rackdiag
rackdiag {
  default_textcolor = "#1a1a2e";
  default_fontsize = 11;

  class power   [color = "#cccccc"];
  class compute [color = "#d9ead3"];
  class storage [color = "#fce5cd"];
  class network [color = "#cfe2f3"];

  42U;
  1: PDU [1U]              [class = "power"];
  2: UPS [3U]             [class = "power"];
  6: Web Server           [class = "compute"];
  7: Web Server           [class = "compute"];
  8: App Server           [class = "compute"];
  12: Database [2U]       [class = "storage"];
  16: Storage Array [4U]  [class = "storage"];
  22: Core Switch [1U]    [class = "network"];
  23: ToR Switch [1U]     [class = "network"];
}
```

### How to lay out a standard 42U production rack
```rackdiag
rackdiag {
  42U;
  ascending;
  1: Patch Panel [1U];
  2: ToR Switch [1U];
  3: Firewall [1U];
  5: Load Balancer [1U];
  7: Web Server [1U];
  8: Web Server [1U];
  10: App Server [2U];
  14: Database Primary [2U];
  16: Database Replica [2U];
  20: Storage Array [4U];
  40: UPS [2U];
  42: PDU [1U];
}
```

### How to draw multiple racks as a rack group
```rackdiag
rackdiag {
  rack {
    24U; description = "Cabinet 1";
    1: UPS [2U]; 3: Server [1U]; 4: Server [1U]; 6: Switch [1U];
  }
  rack {
    24U; description = "Cabinet 2";
    1: UPS [2U]; 3: GPU Node [4U]; 8: GPU Node [4U]; 20: Switch [1U];
  }
}
```

### How to reserve empty units and blank panels
```rackdiag
rackdiag {
  16U;
  1: UPS [2U];
  3: Server [1U];
  // units 4–7 intentionally empty (future expansion)
  8: Server [1U];
  16: Blank Panel [1U];
}
```

## Do's and Don'ts

### ✅ Do
- Open the block with the rack height (`42U;`) before listing any equipment.
- Use `startUnit: Name [NU];` — the number before the colon is the *starting* unit, `[NU]` is the *height*.
- Merge height and style in one bracket when convenient: `6: Database [2U, color = "#fce5cd"];`.
- Add `ascending;` when your convention numbers racks from the top.
- Wrap each rack in `rack { }` when drawing more than one.

### ❌ Don't
- Don't overlap items — two entries claiming the same unit range collide; keep starting units + heights disjoint.
- Don't exceed the frame — `40: Server [4U];` in a `42U;` rack overflows the top.
- Don't confuse the two numbers: `[2U]` is a *height*, not the position — position is the value before the colon.
- Don't run `blockdiag` on a rack file; use the `rackdiag` command.
- Don't quote the height token — write `[2U]`, not `["2U"]`.

## Styling, Theming & Customization
Theming is inline: `color`/`textcolor`/`fontsize` per item, `class` bundles for role-based palettes (power/compute/storage/network), and `default_*` diagram attributes for the baseline. A conventional scheme — grey for power, green for compute, orange for storage, blue for network — reads well and matches typical datacenter documentation. `description` labels each rack in a group.

## Advanced Features
- **Rack groups**: multiple `rack { }` blocks in one `rackdiag` render side by side.
- **Per-rack height**: each `rack { }` sets its own `NU;`.
- **Combined brackets**: `[2U, color = "#fce5cd"]` sets height and style together.
- **Sphinx**: `.. rackdiag::` directive (via sphinxcontrib-nwdiag) renders inline in docs.

## Common Pitfalls & Troubleshooting
- **Item missing or clipped**: it likely overflows the frame — increase `NU;` or lower the starting unit.
- **Two items overlapping**: recompute ranges; a 2U item at unit 3 occupies 3–4, so the next item starts at 5.
- **Numbers upside-down from expectation**: add or remove `ascending;`.
- **PDF fails**: install `"nwdiag[pdf]"`.
- **Non-ASCII labels render as boxes**: pass `-f /path/Font.ttf`.

## Integration Notes
- **Sphinx**: `sphinxcontrib-nwdiag` provides the `.. rackdiag::` directive.
- **Kroki**: https://kroki.io renders rackdiag server-side — POST the source to `https://kroki.io/rackdiag/svg` with no local install.
- **MkDocs / Markdown**: embed via the `mkdocs-kroki-plugin` or a Kroki fenced block.
- **CI**: `.diag` sources diff cleanly; render to SVG in a build step or via Kroki on demand.

## Best For / Avoid For
`rack-elevation`, `datacenter-layout`, `capacity-planning`, `hardware-inventory`, `deployment-docs` — choose rackdiag when you need accurate U-positioned rack views from text. Avoid for logical network topology (use nwdiag), packet layouts (packetdiag), or general diagrams (blockdiag/graphviz/mermaid).

## See Also
- Family siblings: `nwdiag.md` (network topology), `packetdiag.md` (packet fields), `blockdiag.md` (core blocks/flow), `seqdiag.md` (sequence), `actdiag.md` (activity)
- Alternatives: `mermaid.md` (Markdown diagrams), `graphviz.md` (DOT graph layout)
- Use cases: `../use-case/networks-graphs.md`, `../use-case/diagram-generation.md`
