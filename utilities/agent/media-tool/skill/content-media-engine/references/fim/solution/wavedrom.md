# WaveDrom — Digital Timing Diagrams from WaveJSON

WaveDrom renders digital timing diagrams, bit-field register maps, and simple
logic schematics from a compact JSON description (WaveJSON). It runs in the
browser, on the command line, and inside many Markdown/doc pipelines, emitting
crisp SVG (and PNG via the CLI). It is the de-facto standard for embedding
timing waveforms in datasheets, RFCs, and hardware documentation.

**Current Version**: wavedrom 3.x (current major)  **License**: MIT
**Runtime**: browser JS (`skins` + `wavedrom.js`), Node CLI, Python wrapper

## Official Resources & Documentation
- Home & live editor: https://wavedrom.com/ and https://wavedrom.com/editor.html
- Tutorial: https://wavedrom.com/tutorial.html
- GitHub: https://github.com/wavedrom/wavedrom
- CLI: https://github.com/wavedrom/cli (`npm i -g wavedrom-cli`)
- npm: https://www.npmjs.com/package/wavedrom
- Python wrapper: https://pypi.org/project/wavedrom/
- Bit-field companion: https://github.com/wavedrom/bitfield

## Installation & Setup

### Command line (Node)
```bash
npm install -g wavedrom-cli
wavedrom-cli -i clock.json -s clock.svg      # -s SVG, -p PNG
```

### Python wrapper
```bash
pip install wavedrom
```
```python
import wavedrom
svg = wavedrom.render("""{ "signal": [{ "name": "clk", "wave": "p...." }] }""")
svg.saveas("clk.svg")
```

### Browser (CDN)
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/wavedrom/3.5.0/skins/default.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/wavedrom/3.5.0/wavedrom.min.js"></script>
<body onload="WaveDrom.ProcessAll()">
  <script type="WaveDrom">
  { "signal": [{ "name": "clk", "wave": "p......" }] }
  </script>
</body>
```

### Markdown fence
Many renderers accept a ```` ```wavedrom ```` fence whose body is WaveJSON.

## Core Syntax / API Reference

A WaveJSON document is a JSON object. The three most important keys are
`signal` (the waveform rows), `config`, and `head`/`foot`.

### The `wave` string — one character = one clock period
```json
{ "signal": [
  { "name": "clk",  "wave": "p......" },
  { "name": "bus",  "wave": "x.==.=x", "data": ["A", "B", "C"] },
  { "name": "req",  "wave": "0.1..0." }
]}
```

**Wave character alphabet:**

| Char | Meaning |
|------|---------|
| `p` `n` | clock, positive / negative edge (no arrow) |
| `P` `N` | clock with edge arrow marker |
| `l` `h` | low / high level, forces a fresh transition |
| `L` `H` | low / high with an arrow marker |
| `0` `1` | logic low / high level |
| `x` | don't-care (hatched) |
| `z` | high-impedance (mid-level line) |
| `=` | data cell, default color (fill 2) |
| `2`–`9` | data cell, palette colors 2 through 9 |
| `.` | extend the previous cell one more period |
| `\|` | gap / break marker (elides omitted time) |
| `u` `d` | pull-up / pull-down (RC-style soft edge) |

- `data` supplies the text drawn inside `=`/`2`–`9` cells, left-to-right.
- `.` is a repeat, **not** a low level — reuse it to hold a value.
- `|` splits the diagram to indicate skipped cycles; it consumes one period.

### Per-signal keys
```json
{ "name": "addr", "wave": "x3.x", "data": ["0xF0"],
  "phase": 0.5, "period": 2, "node": ".a.." }
```
- `phase` — shift the row left (positive) in fractions of a period.
- `period` — stretch each character of this row by N (useful for slow clocks).
- `node` — name anchor points for edges/arrows (see below).

### Groups (nested signals)
A nested array whose first element is a string becomes a labeled group:
```json
{ "signal": [
  ["Control",
    { "name": "req",  "wave": "0.1.0" },
    { "name": "ack",  "wave": "0..1." }
  ],
  {},
  { "name": "clk", "wave": "p...." }
]}
```
An empty object `{}` inserts a blank spacer row.

### Edges & arrows
Declare `node` anchors on rows, then draw between them with `edge`:
```json
{ "signal": [
  { "name": "A", "wave": "01..0", "node": ".a..." },
  { "name": "B", "wave": "0..1.", "node": "...b." }
], "edge": ["a~>b setup", "a-|b"] }
```
Arrow operators: `-` sharp line, `~` spline, `->`/`~>` arrowheads,
`-|`, `|-`, `-|>`, `<->`, `<~>`. Trailing text becomes the label.

### `config`
```json
{ "signal": [], "config": { "hscale": 2, "skin": "default" } }
```
- `hscale` — horizontal zoom (1 default, 2 = twice as wide).
- `skin` — `"default"`, `"narrow"`, or `"lowkey"` (must load matching skin JS).

### `head` / `foot`
```json
{ "signal": [{ "name": "clk", "wave": "p....." }],
  "head": { "text": "Read cycle", "tick": 0 },
  "foot": { "text": "t=[ns]", "tock": 0, "every": 2 } }
```
- `text` — caption (string, or rich `["tspan", ...]` markup).
- `tick` — number cycles starting at value N above the diagram.
- `tock` — same, below; `every` labels every Nth cycle.

## Diagram / Output Types
- **Timing waveforms** — the `signal` form above (clocks, buses, control).
- **Bit-field register maps** — the `reg` form (see below), via wavedrom-bitfield.
- **Logic schematics** — the `assign` form for gate/expression trees.

### Bit-field register
```json
{ "reg": [
  { "bits": 8, "name": "data" },
  { "bits": 4, "name": "op", "attr": "RO" },
  { "bits": 4, "name": "rsvd", "type": 1 }
], "config": { "bits": 16, "lanes": 1 } }
```

### Logic (assign)
```json
{ "assign": [
  ["out",
    ["|",
      ["&", "a", "b"],
      ["~", "c"]
    ]
  ]
]}
```

## How-To (worked recipes)

### How to add colors / highlight data on a bus
Data cells `2`–`9` map to the skin's color palette; `=` is color 2. Assign
different digits to visually separate transactions:
```json
{ "signal": [
  { "name": "clk",  "wave": "p......." },
  { "name": "data", "wave": "x3.4.5.x", "data": ["req", "burst", "resp"] }
]}
```
`3` `4` `5` render in distinct fill colors — no CSS needed.

### How to show setup/hold or causality with arrows
```json
{ "signal": [
  { "name": "clk",  "wave": "p....", "node": "..a.." },
  { "name": "d",    "wave": "x3.x.", "node": ".b...", "data": ["D"] }
], "edge": ["b~>a t_su"] }
```
The spline arrow from the data edge to the clock edge is labeled `t_su`.

### How to elide long idle stretches with a gap
Use `|` to break the timeline so a 1000-cycle wait fits on one line:
```json
{ "signal": [
  { "name": "clk", "wave": "p.|..p" },
  { "name": "irq", "wave": "0.|..1" }
]}
```

### How to slow one signal relative to the clock
Give the slow row a larger `period` so each of its characters spans multiple
fast-clock cycles:
```json
{ "signal": [
  { "name": "clk",  "wave": "p........", "period": 1 },
  { "name": "clk/4","wave": "p..",       "period": 4 }
]}
```

### How to number cycles for reference
```json
{ "signal": [{ "name": "clk", "wave": "p....." }],
  "head": { "tick": 0 }, "foot": { "tock": 1, "every": 2 } }
```

## Do's and Don'ts

### ✅ Do
- Keep every row's `wave` the same total length (accounting for `period`) so
  columns line up.
- Use `.` to hold a value across cycles — `"0..1.."` reads as low-hold-rise-hold.
- Put a bare `{}` between logical groups for breathing room.
- Provide `data` in the exact left-to-right order the data cells appear.
- Pick a `skin` and load its JS **before** `wavedrom.min.js` in the browser.

### ❌ Don't
- Don't repeat a level char to "hold" it (`"0000"` = four transitions); use
  `"0..."` instead — repeated literals redraw edges and look wrong.
- Don't forget `data` for `=`/`2`–`9` cells — they render as empty boxes.
- Don't mix `p`/`n` clock chars with manual `0`/`1` on the same clock row.
- Don't exceed the `config.bits` total when summing `reg` bit widths — the map
  silently truncates.
- Don't rely on trailing whitespace inside `wave` strings; it counts as cells.

## Styling, Theming & Customization
- **Skins** control all colors, stroke, and font: `default` (blue accents),
  `narrow` (tighter pitch), `lowkey` (muted greyscale for print). Set via
  `config.skin` and load the matching `skins/<name>.js`.
- **Data cell colors** come from the skin palette indices `2`–`9`; there is no
  per-cell hex override in core WaveJSON — swap the skin to restyle.
- **CSS**: rendered SVG carries classes (e.g. `.wave`, `.gap`); you can post-
  style stroke/fill in the host page after `ProcessAll()`.
- **Fonts** inherit from the skin; the `narrow` skin is best for dense buses.

## Advanced Features
- **Rich caption markup** — `head.text`/`foot.text` accept `["tspan", {...}]`
  arrays for bold/colored labels.
- **Bit-field lanes** — `config.lanes` wraps a wide register onto multiple rows.
- **Programmatic render** — `WaveDrom.RenderWaveForm(index, source, "elemPrefix")`
  or the Node/Python `render()` API for batch SVG generation.
- **VCD import** — pair with `vcd2wavedrom` to turn simulator dumps into WaveJSON.

## Common Pitfalls & Troubleshooting
- **Blank data boxes** → you used `=`/digits without a matching `data` array.
- **Misaligned columns** → row lengths differ; count characters × `period`.
- **Arrows don't appear** → `node` anchors missing, or edge names don't match
  the letters placed in the `node` strings.
- **Skin not applied / uncolored** → skin JS loaded after `wavedrom.min.js`, or
  `config.skin` names a skin you didn't include.
- **CLI PNG blurry** → increase `config.hscale` rather than upscaling the raster.

## Integration Notes
- GitHub/GitLab Markdown do not render WaveDrom natively; use a preprocessor,
  the CLI to pre-bake SVG, or an MkDocs/Sphinx plugin.
- Sphinx: `sphinxcontrib-wavedrom`. MkDocs: community `wavedrom` plugins.
- For LLM authoring, emit a single JSON object — never wrap it in extra prose
  inside the fence.

## Best For / Avoid For
`digital-timing`, `register-maps`, `protocol-waveforms`, `datasheet-figures` —
choose WaveDrom for clocked digital signals and bit-fields.
Avoid for analog waveforms, S-parameter/eye diagrams, or richly annotated
protocol sequence charts (use SPICE plots or sequence diagrams instead).

## See Also
- [wavejson.md](wavejson.md) — the underlying data format in depth
- [digital-timing.md](digital-timing.md) — alternative timing toolchains (tikz-timing)
- [circuitikz.md](circuitikz.md) — schematics to accompany timing figures
- [verilog-diag.md](verilog-diag.md) — RTL netlists that produce these waveforms
- ../use-case/engineering-diagrams.md
