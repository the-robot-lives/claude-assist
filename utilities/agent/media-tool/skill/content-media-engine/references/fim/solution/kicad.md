# KiCad — S-Expression Schematic & PCB File Formats

KiCad is the open-source EDA suite for schematic capture and PCB layout. Since
v6 all its design files are human-readable **S-expressions** (`.kicad_sch`,
`.kicad_pcb`, `.kicad_sym`, `.kicad_mod`), which makes them scriptable,
diffable, and generatable. This file documents that on-disk format plus the
`pcbnew` Python API and `kicad-cli` export path — the surfaces an agent uses to
produce or transform KiCad designs.

**Current Version**: KiCad 8 / 9 (current)  **License**: GPL v3
**Formats**: S-expression (post-v6); legacy `.sch`/`.lib` are pre-v6 only

## Official Resources & Documentation
- Home: https://www.kicad.org/
- File format docs: https://dev-docs.kicad.org/en/file-formats/
- S-expression reference: https://dev-docs.kicad.org/en/file-formats/sexpr-intro/
- pcbnew Python API: https://docs.kicad.org/doxygen-python/
- kicad-cli: https://docs.kicad.org/8.0/en/cli/cli.html
- SKiDL (Python netlists): https://github.com/devbisme/skidl

## Installation & Setup

### Application
```bash
# macOS
brew install --cask kicad
# Debian/Ubuntu
sudo add-apt-repository ppa:kicad/kicad-8.0-releases && sudo apt install kicad
# Windows: installer from kicad.org
```

### Scripting environments
```bash
# pcbnew Python module ships inside KiCad; use its bundled interpreter,
# or point PYTHONPATH at it. SKiDL is standalone:
pip install skidl
```

### Project file family
```
project/
├── project.kicad_pro   # project settings (JSON)
├── project.kicad_sch   # schematic (S-expr)
├── project.kicad_pcb   # board layout (S-expr)
├── sym-lib-table       # symbol library table
├── fp-lib-table        # footprint library table
└── project.kicad_sym   # local symbol library (S-expr)
```

## Core Syntax / API Reference

### S-expression grammar
Everything is `(token value …)`; whitespace-separated, parens-nested. Strings
are quoted; numbers are bare; coordinates are millimeters.
```lisp
(kicad_sch
  (version 20231120)
  (generator "eeschema")
  (uuid "0f3b…")
  (paper "A4")
)
```

### Schematic (`.kicad_sch`) — key nodes
```lisp
(kicad_sch
  (version 20231120) (generator "eeschema")
  (lib_symbols
    (symbol "Device:R" (pin_numbers hide) (pin_names (offset 0))
      (property "Reference" "R" (at 2.032 0 90))
      (property "Value" "R" (at 0 0 90))
      ; … symbol graphics …
    )
  )
  (symbol
    (lib_id "Device:R")
    (at 100.33 76.2 0)
    (unit 1)
    (uuid "a1b2…")
    (property "Reference" "R1" (at 102.87 74.93 0))
    (property "Value" "10k"  (at 102.87 77.47 0))
    (pin "1" (uuid "…")) (pin "2" (uuid "…"))
  )
  (wire (pts (xy 100.33 76.2) (xy 110.49 76.2))
        (stroke (width 0) (type default)) (uuid "…"))
  (junction (at 110.49 76.2) (diameter 0) (color 0 0 0 0))
  (label "VOUT" (at 110.49 76.2 0) (fields_hidden yes))
  (global_label "GND" (shape input) (at 100 90 0))
  (no_connect (at 120 76.2) (uuid "…"))
)
```
- `symbol` = a placed component (references a `lib_id`).
- `wire` = a net segment (`pts` list of `xy`).
- `label` / `global_label` / `hierarchical_label` = net naming.
- `junction` = electrical connection dot; `no_connect` = intentional NC flag.

### PCB (`.kicad_pcb`) — key nodes
```lisp
(kicad_pcb
  (version 20231014) (generator "pcbnew")
  (general (thickness 1.6))
  (layers
    (0 "F.Cu" signal) (31 "B.Cu" signal)
    (36 "B.SilkS" user) (37 "F.SilkS" user)
    (44 "Edge.Cuts" user)
  )
  (net 0 "") (net 1 "VCC") (net 2 "GND")
  (footprint "Resistor_SMD:R_0805_2012Metric"
    (layer "F.Cu") (at 120 80 0) (uuid "…")
    (property "Reference" "R1" (at 0 -1.5 0) (layer "F.SilkS"))
    (pad "1" smd roundrect (at -1 0) (size 1.2 1.4) (layers "F.Cu" "F.Paste" "F.Mask")
         (net 1 "VCC")))
  (segment (start 120 80) (end 130 80) (width 0.25) (layer "F.Cu") (net 1))
  (via (at 130 80) (size 0.8) (drill 0.4) (layers "F.Cu" "B.Cu") (net 1))
  (gr_line (start 100 60) (end 160 60) (stroke (width 0.1) (type solid)) (layer "Edge.Cuts"))
  (zone (net 2) (net_name "GND") (layer "B.Cu") (hatch edge 0.5) …)
)
```
- `footprint` = placed part; `pad` = its lands with `net` assignment.
- `segment` = copper track; `via` = layer-to-layer connection.
- `gr_line`/`gr_poly` = graphic lines (board outline on `Edge.Cuts`).
- `zone` = copper pour (ground/power planes).

### pcbnew Python API
```python
import pcbnew
board = pcbnew.LoadBoard("project.kicad_pcb")
for fp in board.GetFootprints():          # v6+; GetModules() was v5
    print(fp.GetReference(), fp.GetPosition())
for track in board.GetTracks():
    print(track.GetNetname(), track.GetWidth())
pcbnew.SaveBoard("out.kicad_pcb", board)
```

### kicad-cli (headless export)
```bash
kicad-cli sch export svg  project.kicad_sch -o out/
kicad-cli sch export pdf  project.kicad_sch -o sch.pdf
kicad-cli pcb export gerbers project.kicad_pcb -o gerbers/
kicad-cli pcb export step  project.kicad_pcb -o board.step
kicad-cli pcb export svg   project.kicad_pcb -o board.svg
```

## Output / Export Types
- **Schematic**: SVG, PDF, netlist, BOM (via `kicad-cli sch export ...`).
- **PCB**: Gerber (RS-274X), Excellon drill, STEP/VRML 3D, SVG, PDF, pos files.
- **Symbols/footprints**: `.kicad_sym`, `.kicad_mod` libraries.

## How-To (worked recipes)

### How to set layer colors / silkscreen & copper styling (the "add color" recipe)
Board colors are **theme**-driven, not stored per-object; per-graphic stroke
color is set with a `(color r g b a)` node, and objects choose a `layer` whose
theme color they inherit:
```lisp
(gr_line (start 0 0) (end 10 0)
  (stroke (width 0.2) (type solid) (color 255 0 0 1))
  (layer "F.SilkS"))
```
Change the whole-board palette in Preferences → Colors, or ship a color theme
JSON; individual copper fills take the net-class/layer theme color.

### How to add a resistor symbol to a schematic
```lisp
(symbol (lib_id "Device:R") (at 90 70 0) (unit 1) (uuid "…")
  (property "Reference" "R2" (at 92 68 0))
  (property "Value" "4.7k" (at 92 72 0))
  (pin "1" (uuid "…")) (pin "2" (uuid "…")))
(wire (pts (xy 90 70) (xy 100 70)) (stroke (width 0) (type default)) (uuid "…"))
```

### How to route a copper track and stitch a via
```lisp
(segment (start 120 80) (end 120 95) (width 0.25) (layer "F.Cu") (net 1))
(via (at 120 95) (size 0.8) (drill 0.4) (layers "F.Cu" "B.Cu") (net 1))
(segment (start 120 95) (end 135 95) (width 0.25) (layer "B.Cu") (net 1))
```

### How to generate a netlist from Python with SKiDL
```python
from skidl import Part, Net, generate_netlist
vcc, gnd, out = Net('VCC'), Net('GND'), Net('OUT')
r1 = Part('Device', 'R', value='10k')
c1 = Part('Device', 'C', value='100n')
vcc & r1 & out & c1 & gnd          # series connect
generate_netlist(file_='rc.net')
```

### How to batch-export fabrication files
```bash
kicad-cli pcb export gerbers project.kicad_pcb -o fab/ \
  && kicad-cli pcb export drill project.kicad_pcb -o fab/
```

## Do's and Don'ts

### ✅ Do
- Treat `.kicad_sch`/`.kicad_pcb` as generated artifacts: keep every object's
  `uuid` unique and stable across edits.
- Use `kicad-cli` for reproducible, headless exports in CI.
- Prefer `board.GetFootprints()` / `GetTracks()` (v6+ API), not the v5 names.
- Assign every pad/segment a valid `net` index that exists in the `(net …)` list.
- Author symbols/footprints in libraries and *reference* them via `lib_id`.

### ❌ Don't
- Don't hand-edit coordinates so parts overlap — DRC will reject the board.
- Don't call `GetModules()` on KiCad 6+ (removed); it silently breaks scripts.
- Don't drop the `(version …)` token — KiCad refuses files it can't version.
- Don't reuse a `uuid` across two objects; cross-references corrupt.
- Don't expect the legacy `.sch`/`.lib` format to load in v6+ without migration.

## Styling, Theming & Customization
- **Layers** carry the visual identity: `F.Cu`/`B.Cu` (copper), `*.SilkS`
  (silkscreen), `*.Mask`, `Edge.Cuts` (outline). Object `layer` picks the color.
- **Themes**: color palettes live in JSON theme files (Preferences → Colors);
  the design files store geometry, not the palette (except explicit `color`).
- **Stroke nodes**: `(stroke (width w) (type solid|dash|dot) (color r g b a))`
  on graphics.
- **Net classes** set default track width/clearance per net group.

## Advanced Features
- **Python plugins / action scripts** inside pcbnew for automated placement/DRC.
- **IPC-2581 / ODB++** and STEP/VRML 3D export for downstream tooling.
- **Hierarchical sheets** (`sheet` nodes) for large multi-page schematics.
- **DRC/ERC** rule files; custom design rules in the `.kicad_pcb`.
- **SKiDL** for fully code-defined netlists that KiCad imports.

## Common Pitfalls & Troubleshooting
- **File won't open** → missing/incorrect `(version …)` or unbalanced parens.
- **Ratsnest but no connection** → pads reference a net not in the `(net …)` map.
- **Script AttributeError** → v5 API names (`GetModules`) on a v6+ board.
- **Gerbers wrong** → export layer set incomplete; use `kicad-cli` presets.
- **Merge conflicts** → concurrent edits shuffle `uuid`/order; edit atomically.

## Integration Notes
- `kicad-cli` makes KiCad CI-friendly (Gerbers/PDF/SVG/STEP without the GUI).
- SKiDL + KiCad libraries let an agent emit netlists programmatically.
- Not a diagram-in-Markdown tool — export SVG/PDF for docs.

## Best For / Avoid For
`pcb-design`, `schematic-capture`, `manufacturing`, `gerbers`, `3d-export` —
choose KiCad when the goal is a real, fabricable board or a rigorous schematic.
Avoid for quick illustrative schematics in a paper (use CircuiTikZ/SchemDraw)
or breadboard teaching visuals (use Fritzing).

## See Also
- [fritzing.md](fritzing.md) — breadboard-first, education-oriented EDA
- [circuitikz.md](circuitikz.md) — schematic *figures* for LaTeX docs
- [schemdraw.md](schemdraw.md) — code-drawn schematics
- [spice-netlist.md](spice-netlist.md) — simulate exported netlists
- ../use-case/engineering-diagrams.md
