# WaveJSON — The Timing-Diagram Interchange Format

WaveJSON is the plain-JSON schema that describes digital timing waveforms, bit-
field register maps, and logic expressions. It is the *data model* that WaveDrom
(and several converters) consume — tool-agnostic, diff-friendly, and trivial to
generate from code. This file documents the format itself; see `wavedrom.md`
for the reference renderer.

**Format**: JSON5-tolerant object  **License**: format is open (WaveDrom MIT)
**Renderers**: WaveDrom, wavedrom-cli, `wavedrom` (Python), online editors

## Official Resources & Documentation
- Spec & tutorial: https://wavedrom.com/tutorial.html
- WaveJSON wiki: https://github.com/wavedrom/wavedrom/wiki/WaveJSON
- Reference renderer: https://github.com/wavedrom/wavedrom
- Converters: `vcd2wavedrom` (https://github.com/Toroid-io/vcd2wavedrom)
- Bit-field renderer: https://github.com/wavedrom/bitfield
- Online editor: https://wavedrom.com/editor.html

## Installation & Setup
WaveJSON is data, not a library — you author `.json` and hand it to a renderer.

### Validate / render toolchain
```bash
npm install -g wavedrom-cli          # render WaveJSON -> SVG/PNG
pip install wavedrom                  # Python renderer
pip install vcd2wavedrom              # convert VCD dumps -> WaveJSON
```

### Minimal document
```json
{ "signal": [ { "name": "clk", "wave": "p......" } ] }
```
JSON5 is tolerated by the editor (unquoted keys, comments), but emit **strict
JSON** for portability across converters and Markdown pipelines.

## Core Syntax / API Reference

### Top-level keys
| Key | Type | Purpose |
|-----|------|---------|
| `signal` | array | waveform rows (and groups) — the timing model |
| `reg` | array | bit-field register description (alternative to `signal`) |
| `assign` | array | logic expression tree for gate diagrams |
| `config` | object | `hscale`, `skin`, `bits`, `lanes` |
| `head` | object | top caption / tick numbering |
| `foot` | object | bottom caption / tock numbering |
| `edge` | array | arrow/label declarations referencing `node` anchors |

Exactly one of `signal`, `reg`, or `assign` is the diagram body.

### Signal object schema
```json
{
  "name":   "data",
  "wave":   "x.=.x",
  "data":   ["payload"],
  "node":   ".a...",
  "phase":  0,
  "period": 1
}
```
- **name** — row label (string; may be empty).
- **wave** — one char per period; alphabet below.
- **data** — text for data cells, space-delimited string *or* array of strings.
- **node** — anchor letters for `edge` arrows (`.` = no anchor at that period).
- **phase** — horizontal shift in fractional periods.
- **period** — per-row time stretch (integer ≥ 1).

### Wave alphabet (canonical)
```
clocks : p n P N        (P/N add edge-arrow markers)
levels : 0 1 l h L H    (l/h force transition; L/H add arrow)
special: x (dontcare)  z (hi-Z)  u (pull-up)  d (pull-down)
data   : = 2 3 4 5 6 7 8 9   (= is color 2; digits pick palette color)
control: . (hold/extend)      | (gap; consumes one period)
```

### Grouping & spacers
```json
{ "signal": [
  ["bus group",
    { "name": "addr", "wave": "x=x", "data": ["A0"] },
    { "name": "data", "wave": "x=x", "data": ["D0"] }
  ],
  {},
  { "name": "clk", "wave": "p.." }
]}
```
- Nested array with a leading string → named group.
- Empty object `{}` → blank spacer row.

### Register (`reg`) schema
```json
{ "reg": [
  { "bits": 4, "name": "op",   "attr": "RW" },
  { "bits": 8, "name": "addr" },
  { "bits": 4, "name": "rsvd", "type": 1 }
], "config": { "bits": 16, "lanes": 2 } }
```
- **bits** — field width; the sum should equal `config.bits`.
- **name** — field label (omit for anonymous).
- **attr** — text/array annotation drawn under the field.
- **type** — palette index for the field fill (styling only).

### Logic (`assign`) schema
Nested arrays are `[operator, ...operands]`; leaves are wire-name strings:
```json
{ "assign": [
  ["Y",
    ["&",
      ["|", "a", "b"],
      ["~", "c"]
    ]
  ]
]}
```
Operators: `&` `|` `^` (and/or/xor), `~` (not), and buffered variants.

## Diagram / Output Types
- **Timing** — via `signal`.
- **Register / bit-field** — via `reg`.
- **Logic gate tree** — via `assign`.
All three are rendered to SVG by the same WaveDrom engine.

## How-To (worked recipes)

### How to color-code transactions on a shared bus
Digits `2`–`9` select distinct palette colors for data cells:
```json
{ "signal": [
  { "name": "clk",  "wave": "p......" },
  { "name": "data", "wave": "x2.3.4x", "data": ["hdr", "body", "crc"] }
]}
```

### How to generate WaveJSON from a simulator dump
```bash
vcd2wavedrom -i dump.vcd -o wave.json -c config.json
wavedrom-cli -i wave.json -s wave.svg
```
The `config.json` picks which signals/time-window to extract.

### How to emit WaveJSON programmatically
```python
import json
rows = [{"name": "clk", "wave": "p" + "." * 7}]
for i, sig in enumerate(("req", "ack")):
    rows.append({"name": sig, "wave": "0" + ".1.0..."[:7]})
print(json.dumps({"signal": rows}, indent=2))
```
Because it is ordinary JSON, any language can build it with its native encoder.

### How to annotate with tick numbers and a caption
```json
{ "signal": [{ "name": "clk", "wave": "p....." }],
  "head": { "text": "SPI mode 0", "tick": 0 },
  "foot": { "text": "cycles", "tock": 0 } }
```

### How to draw a timing arrow between two edges
```json
{ "signal": [
  { "name": "clk", "wave": "p...", "node": "..a." },
  { "name": "d",   "wave": "x=x.", "node": ".b..", "data": ["D"] }
], "edge": ["b~>a t_su"] }
```

## Do's and Don'ts

### ✅ Do
- Emit strict JSON (double-quoted keys/strings) for converter compatibility.
- Keep row lengths consistent so cycles align vertically.
- Use `.` to hold a value; never repeat a level char to hold it.
- Keep `data` order matching data-cell order, left to right.
- Sum `reg` bit widths to exactly `config.bits`.

### ❌ Don't
- Don't embed comments/trailing commas in files fed to non-editor tools.
- Don't put more `data` entries than there are data cells (extras are ignored)
  or fewer (later cells render empty).
- Don't reference `edge` letters that no `node` string defines.
- Don't assume a renderer supports analog — WaveJSON is digital-only.
- Don't rely on `phase`/`period` for precise nanosecond timing; they are
  visual, not a simulation timebase.

## Styling, Theming & Customization
- Styling lives in the **renderer skin**, not the WaveJSON: `config.skin` picks
  `default` / `narrow` / `lowkey`. Data-cell colors come from palette indices
  (`=`→2, `2`–`9`).
- There is no per-cell hex color in the format; restyle by choosing a skin or
  post-processing the emitted SVG's CSS classes.
- `config.hscale` zooms horizontally; `config.lanes` wraps wide registers.

## Advanced Features
- **Rich text captions** — `head.text`/`foot.text` accept `["tspan", {attrs},
  "text"]` arrays for inline styling.
- **Multi-lane registers** — `config.lanes` splits a wide `reg` across rows.
- **Round-trip** — VCD → WaveJSON → SVG makes simulator output publishable.
- **Schema linting** — validate against the community JSON schema before render
  to catch width/length mismatches early.

## Common Pitfalls & Troubleshooting
- **Renderer rejects file** → likely JSON5 syntax (comments/unquoted keys) sent
  to a strict parser; re-serialize as strict JSON.
- **Empty data boxes** → data cells without matching `data`.
- **Register overflow** → `reg` widths sum beyond `config.bits`; the map clips.
- **Ghost columns** → trailing spaces inside `wave` strings count as periods.
- **Arrows missing** → `node`/`edge` letters mismatched.

## Integration Notes
- Treat WaveJSON as a versioned artifact in git; it diffs cleanly line-by-line.
- Pair with CI to pre-render SVG for docs (Sphinx `sphinxcontrib-wavedrom`,
  MkDocs plugins, or a plain `wavedrom-cli` build step).
- LLM authoring: output one JSON object, no surrounding markdown, valid strict
  JSON only.

## Best For / Avoid For
`interchange`, `codegen`, `version-control`, `digital-timing` — choose WaveJSON
as the format when you generate waveforms from code or store them in a repo.
Avoid for analog/mixed-signal traces and for anything needing per-cell hex
theming without a custom skin.

## See Also
- [wavedrom.md](wavedrom.md) — the reference renderer and CLI
- [digital-timing.md](digital-timing.md) — LaTeX/tikz-timing alternatives
- [verilog-diag.md](verilog-diag.md) — RTL sources that produce these dumps
- ../use-case/engineering-diagrams.md
