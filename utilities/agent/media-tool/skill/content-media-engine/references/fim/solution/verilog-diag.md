# Verilog Diagrams — RTL & Netlist Visualization

"Verilog diagram" covers the toolchain that turns Verilog/SystemVerilog HDL into
pictures: **Yosys** synthesizes/elaborates the design to a JSON netlist or a
Graphviz graph, **netlistsvg** renders that JSON to a schematic-style SVG, and
**WaveDrom** draws the resulting timing. You can also hand-author the netlistsvg
JSON directly. This file documents those source surfaces for generating logic
schematics from HDL.

**Primary tools**: Yosys 0.3x+, netlistsvg 1.x, pyverilog  **License**: ISC/MIT
**Output**: SVG (netlistsvg), DOT/SVG (Yosys `show`), JSON netlist

## Official Resources & Documentation
- Yosys: https://yosyshq.net/yosys/ , docs https://yosyshq.readthedocs.io/
- netlistsvg: https://github.com/nturley/netlistsvg
- DigitalJS (browser sim from Yosys JSON): https://github.com/tilk/digitaljs
- pyverilog: https://github.com/PyHDI/Pyverilog
- WaveDrom (timing): https://wavedrom.com/ — see `wavedrom.md`
- Yosys JSON format: https://yosyshq.readthedocs.io/projects/yosys/en/latest/cmd/write_json.html

## Installation & Setup
```bash
# Synthesis / elaboration
sudo apt-get install yosys            # or: brew install yosys
# Netlist -> SVG
npm install -g netlistsvg
# HDL analysis in Python
pip install pyverilog                 # needs Icarus Verilog (iverilog) for preprocessing
# Timing
npm install -g wavedrom-cli
```

## Core Syntax / API Reference

### Yosys → JSON netlist
```bash
yosys -p "read_verilog design.v; hierarchy -top top; proc; opt; write_json design.json"
```
Common command pipeline stages:
- `read_verilog file.v` / `read_verilog -sv file.sv` — load HDL.
- `hierarchy -top <name>` — set the top module, resolve instances.
- `proc` — convert processes (always blocks) to netlist logic.
- `flatten` — inline submodules into one level (optional).
- `opt` — constant-fold / clean up.
- `synth` — full synthesis to gate primitives (for gate-level views).
- `write_json out.json` — emit the netlistsvg-compatible JSON.

### Yosys → Graphviz directly
```bash
yosys -p "read_verilog design.v; prep -top top; show -format svg -prefix out"
# 'show' also accepts -colors, -width, -stretch
```

### netlistsvg render
```bash
netlistsvg design.json -o design.svg
netlistsvg design.json --skin analog.svg -o design.svg   # pick a skin
```

### netlistsvg JSON schema (hand-authorable)
The renderer consumes a Yosys-JSON subset; you can write it directly:
```json
{
  "modules": {
    "top": {
      "ports": {
        "a": { "direction": "input",  "bits": [2] },
        "b": { "direction": "input",  "bits": [3] },
        "y": { "direction": "output", "bits": [4] }
      },
      "cells": {
        "u_and": {
          "type": "$and",
          "port_directions": { "A": "input", "B": "input", "Y": "output" },
          "connections": { "A": [2], "B": [3], "Y": [4] }
        }
      }
    }
  }
}
```
- **bits** are integer net IDs; shared IDs mean a wire connects those pins.
- Constant nets use the strings `"0"`, `"1"`, `"x"`, `"z"` in a bits array.
- Recognized cell **type**s (default skin): `$and $or $not $xor $xnor $nand
  $nor $mux $dff $add $sub $eq generic`.

### pyverilog (AST / dataflow)
```python
from pyverilog.vparser.parser import parse
ast, directives = parse(["design.v"])
ast.show()                      # dump the AST

from pyverilog.dataflow.dataflow_analyzer import VerilogDataflowAnalyzer
a = VerilogDataflowAnalyzer("top.v", "top")
a.generate()
terms = a.getTerms()            # signal terms and their dependencies
```

## Diagram / Output Types
- **RTL schematic** — netlistsvg from `proc; opt` JSON (register-transfer view).
- **Gate-level schematic** — netlistsvg from `synth` JSON (primitive gates).
- **Hierarchy/graph** — Yosys `show` Graphviz output.
- **Dataflow graph** — pyverilog term/dependency graph.
- **Timing** — WaveDrom waveforms of the simulated signals.

## How-To (worked recipes)

### How to style / color the schematic (the "add color" recipe)
netlistsvg styling is **skin**-based; a skin is an SVG template defining cell
shapes, wire stroke, and colors. Pick a built-in skin or edit one:
```bash
netlistsvg design.json --skin default.svg -o design.svg   # boxed digital
netlistsvg design.json --skin analog.svg  -o analog.svg   # analog symbols
netlistsvg design.json --skin minimal.svg -o min.svg      # bare
```
For Yosys `show`, color nodes/nets with `show -colors <seed>` or per-signal
`-color <color> <selection>`.

### How to render an RTL schematic from a module
```bash
yosys -p "read_verilog -sv alu.sv; hierarchy -top alu; proc; opt; write_json alu.json"
netlistsvg alu.json -o alu.svg
```

### How to view module hierarchy as a graph
```bash
yosys -p "read_verilog soc.v; hierarchy -top soc; show -format svg -prefix soc_hier"
```

### How to hand-author a 2-input mux diagram
```json
{ "modules": { "mux2": {
  "ports": {
    "s": {"direction":"input","bits":[2]},
    "a": {"direction":"input","bits":[3]},
    "b": {"direction":"input","bits":[4]},
    "y": {"direction":"output","bits":[5]}
  },
  "cells": {
    "m": { "type":"$mux",
      "port_directions": {"S":"input","A":"input","B":"input","Y":"output"},
      "connections": {"S":[2],"A":[3],"B":[4],"Y":[5]} }
  }
}}}
```
```bash
netlistsvg mux2.json -o mux2.svg
```

### How to pair the schematic with a timing diagram
Author the stimulus/response as WaveJSON and render alongside:
```json
{ "signal": [
  { "name": "s", "wave": "01" },
  { "name": "a", "wave": "x=", "data": ["A"] },
  { "name": "y", "wave": "x=", "data": ["A"] }
]}
```

## Do's and Don'ts

### ✅ Do
- Always `hierarchy -top <name>` before `proc`/`show`; otherwise Yosys guesses.
- Use `proc; opt` for readable RTL views; reserve `synth` for gate-level.
- Keep net **bits** IDs consistent — identical IDs are what forms a wire.
- Choose the smallest skin that reads clearly; edit a copy for custom colors.
- Flatten (`flatten`) only when you actually want one giant level.

### ❌ Don't
- Don't feed testbench/`$display` code to Yosys — it can't synthesize it.
- Don't expect huge designs to render legibly; view one module at a time.
- Don't mix Verilog-2001 and SystemVerilog reads without `-sv` where needed.
- Don't rely on netlistsvg auto-layout for 500-cell modules — it gets cluttered.
- Don't forget constant nets are the strings `"0"/"1"/"x"/"z"`, not integers.

## Styling, Theming & Customization
- **netlistsvg skins** define everything visual: `default.svg` (digital boxes),
  `analog.svg` (analog symbols), `minimal.svg`. Copy a skin and adjust `<g>`
  shape templates / stroke to theme it.
- **Yosys `show`** exposes `-colors <seed>`, `-color <c> <sel>`, `-width`,
  `-stretch`, and label options for the Graphviz output.
- **Cell labels** come from `type`/instance names; rename instances in HDL for
  clearer diagrams.

## Advanced Features
- **DigitalJS** turns the same Yosys JSON into an interactive in-browser
  simulator.
- **Gate-level mapping** — `synth -top t` then a `map` pass for target cells.
- **Formal/coverage** via SymbiYosys (adjacent, not a diagram tool).
- **pyverilog codegen** — regenerate/transform Verilog from the AST.
- **Custom cells** — extend a netlistsvg skin with new `type` templates.

## Common Pitfalls & Troubleshooting
- **Empty/odd diagram** → missing `hierarchy -top`, or top module misnamed.
- **"cannot synthesize" errors** → non-synthesizable constructs (delays, `$`
  system tasks) in the source.
- **Cluttered SVG** → too many cells; view a submodule or raise abstraction with
  `proc; opt` instead of `synth`.
- **netlistsvg cell shows as `generic`** → its `type` isn't in the skin; add it
  or map to a known primitive.
- **Wires not joining** → different `bits` IDs where you meant the same net.

## Integration Notes
- Yosys + netlistsvg are CLI/CI-friendly; wire them into a docs build to keep
  schematics in sync with HDL.
- Pair with WaveDrom for the timing half of a hardware document.
- Not a Markdown-native renderer — commit the produced SVG.

## Best For / Avoid For
`rtl-schematics`, `netlist-viz`, `hdl-docs`, `logic-diagrams` — choose this
toolchain to visualize actual Verilog/SystemVerilog. Avoid for hand-drawn
teaching schematics (use SchemDraw/CircuiTikZ) and for analog circuits (use
SPICE/Lcapy).

## See Also
- [wavedrom.md](wavedrom.md) — timing diagrams for HDL signals
- [wavejson.md](wavejson.md) — the timing interchange format
- [kicad.md](kicad.md) — physical implementation of the design
- [digital-timing.md](digital-timing.md) — alternative timing toolchains
- ../use-case/engineering-diagrams.md
