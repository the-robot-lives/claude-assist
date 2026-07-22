# Fritzing — Breadboard, Schematic & PCB Sketches

⌜fritzing|electronics-design|NPL-FIM@1.0⌝

Fritzing is an open-source EDA tool aimed at makers and educators. Its signature
is the **breadboard view** — a photorealistic wiring picture — kept in sync with
a **schematic** and a **PCB** view of the same circuit. Files are XML: a sketch
(`.fz`, usually zipped into `.fzz`) references part definitions (`.fzp`) and
their per-view SVG graphics. This file documents those formats and the authoring
workflow.

**Current Version**: 1.0.x (0.9.10 long-standing)  **License**: GPL v3+
**Formats**: `.fzz` (zipped sketch), `.fz` (sketch XML), `.fzp` (part XML) + SVG
**Export**: SVG, PNG, PDF, Gerber, Excellon, netlist

## Official Resources & Documentation
- Home: https://fritzing.org/
- Learning / manual: https://fritzing.org/learning/ , https://fritzing.org/learning/manual/
- App source: https://github.com/fritzing/fritzing-app
- Parts repo: https://github.com/fritzing/fritzing-parts
- Part format wiki: https://github.com/fritzing/fritzing-app/wiki/2.1-Fritzing-file-formats
- Forum: https://forum.fritzing.org/

## Installation & Setup
```bash
# macOS
brew install --cask fritzing
# Debian/Ubuntu
sudo apt install fritzing fritzing-parts
# Windows
choco install fritzing
```
Fritzing is primarily GUI-driven; there is no fully-featured headless CLI, so
programmatic use means *authoring/transforming the XML* and opening the sketch to
export. Extra parts install to the user parts folder (`~/.config/Fritzing/parts`).

## Core Syntax / API Reference

### File family
```
sketch.fzz            # ZIP archive:
 ├── sketch.fz         #   the sketch XML (instances, wires, views)
 ├── part.<id>.fzp     #   embedded custom part definitions
 └── svg/…             #   part graphics per view
custom_part.fzp        # standalone part metadata (XML)
```

### Sketch (`.fz`) structure
The sketch lists **instances** (parts *and* wires); each instance carries a
per-view geometry. Wires are themselves instances referencing a wire module.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<module fritzingVersion="1.0.0">
  <instances>
    <instance moduleIdRef="Arduino_Uno_Rev3" modelIndex="1" path=":/parts/…">
      <title>U1</title>
      <views>
        <breadboardView layer="breadboard">
          <geometry x="120" y="50" z="1.5"/>
        </breadboardView>
        <schematicView layer="schematic">
          <geometry x="100" y="100" z="2.5"/>
        </schematicView>
        <pcbView layer="copper1">
          <geometry x="50" y="25" z="1.6"/>
        </pcbView>
      </views>
    </instance>

    <!-- a wire is also an instance -->
    <instance moduleIdRef="WireModuleID" modelIndex="7">
      <views>
        <breadboardView layer="breadboardWire">
          <geometry x="0" y="0" x1="120" y1="60" x2="250" y2="160"/>
          <connectors>
            <connector connectorId="connector0" layer="breadboardWire">
              <geometry x="0" y="0"/>
            </connector>
          </connectors>
        </breadboardView>
      </views>
    </instance>
  </instances>
  <boards>
    <board moduleId="TwoLayerRectanglePCB" title="PCB1" width="50mm" height="30mm"/>
  </boards>
</module>
```

### Part definition (`.fzp`)
A part declares metadata, per-view SVG references, and **connectors**:
```xml
<module fritzingVersion="1.0.0" moduleId="LED_5mm_red" referenceFile="LED.fzp">
  <version>4</version>
  <title>Red LED (5mm)</title>
  <label>LED</label>
  <tags><tag>led</tag><tag>output</tag></tags>
  <properties>
    <property name="family">LED</property>
    <property name="color">red</property>
    <property name="package">THT</property>
  </properties>
  <views>
    <breadboardView><layers image="breadboard/led_bb.svg"><layer layerId="breadboard"/></layers></breadboardView>
    <schematicView><layers image="schematic/led_sch.svg"><layer layerId="schematic"/></layers></schematicView>
    <pcbView><layers image="pcb/led_pcb.svg"><layer layerId="copper1"/></layers></pcbView>
  </views>
  <connectors>
    <connector id="connector0" type="male" name="anode">
      <description>+ anode</description>
      <views>
        <breadboardView><p layer="breadboard" svgId="connector0pin"/></breadboardView>
        <schematicView><p layer="schematic" svgId="connector0pin" terminalId="connector0term"/></schematicView>
        <pcbView><p layer="copper1" svgId="connector0pad"/></pcbView>
      </views>
    </connector>
    <connector id="connector1" type="male" name="cathode"> … </connector>
  </connectors>
</module>
```
- **connector `id`** links a logical pin to an SVG element (`svgId`) in each view.
- **`terminalId`** marks the exact wire-attach point in the schematic SVG.
- **`type`** is `male`/`female`; **buses** group internally-connected pins.

### Views (the three synchronized layers)
- **breadboardView** — photoreal wiring on a breadboard (teaching/sharing).
- **schematicView** — logical symbols and nets.
- **pcbView** — copper layers, pads, board outline; source of Gerbers.

## Output / Export Types
Breadboard/schematic/PCB → SVG, PNG, PDF; PCB → Gerber (RS-274X) + Excellon
drill; plus a simple netlist export. All via the app's File → Export.

## How-To (worked recipes)

### How to color wires and style views (the "add color" recipe)
Wire color is a per-wire property in the sketch; in the app set it via the wire's
Inspector. In XML a wire instance carries a `<wireExtras>` color:
```xml
<instance moduleIdRef="WireModuleID" modelIndex="9">
  <views>
    <breadboardView layer="breadboardWire">
      <geometry x1="120" y1="60" x2="250" y2="160"/>
      <wireExtras mils="16" color="#ff0000" bezier="false"/>
    </breadboardView>
  </views>
</instance>
```
Part graphics colors live in the part SVGs; edit those to restyle a component.

### How to place an Arduino + LED + resistor (breadboard)
1. Drag Arduino Uno, LED, and a 220Ω resistor from the parts bins.
2. Wire: `Pin 13 → 220Ω → LED anode`, `LED cathode → GND`.
3. The corresponding sketch instances/wires are as shown in the structure above.

### How to author a custom part
Create the three view SVGs, then a `.fzp` mapping each connector `id` to the
`svgId` in every view (template above). Load it via Part → Import, or drop the
`.fzp`+SVGs into the user parts folder.

### How to export Gerbers for fabrication
In the PCB view: File → Export → for Production → Extended Gerber. Fritzing
writes copper/silkscreen/mask/outline Gerbers plus an Excellon drill file, ready
for JLCPCB/PCBWay/OSHPark.

### How to share a reproducible sketch
Distribute the single `.fzz` — it bundles the sketch, any custom `.fzp` parts,
and their SVGs, so the recipient opens an identical design.

## Do's and Don'ts

### ✅ Do
- Distribute the `.fzz` (self-contained) rather than a bare `.fz`.
- Keep every connector's `svgId`/`terminalId` matching real SVG element ids.
- Give parts a `family` and sensible `tags` so they're findable and swappable.
- Use buses in `.fzp` for pins that are internally common (e.g. multiple GNDs).
- Route ground/power as buses in breadboard view to reduce wire clutter.

### ❌ Don't
- Don't hand-edit `modelIndex` collisions — each instance index must be unique.
- Don't expect a full headless CLI; plan on the GUI for final export.
- Don't mismatch connector counts between the `.fzp` and its view SVGs — pins
  will fail to attach.
- Don't rely on breadboard auto-routing for PCB; the PCB view needs its own
  routing pass.
- Don't ship a `.fz` referencing custom parts without bundling them (use `.fzz`).

## Styling, Theming & Customization
- **Wire color/width** per wire (`<wireExtras color= mils=>` / Inspector).
- **Component appearance** = the part's per-view SVGs; edit them to restyle.
- **PCB** styling via layer choice (`copper1`/`copper0`/`silkscreen`) and board
  properties (size, layers, finish).
- **Schematic** symbols come from the schematic SVG; swap for IEC/ANSI styles.

## Advanced Features
- **Custom parts editor** (built-in) for new components with all three views.
- **Design-rule check (DRC)** and simple auto-routing in PCB view.
- **Ground-fill / copper pours** and multi-board projects.
- **BOM export** and integration with fab houses (JLCPCB/PCBWay uploads).
- **Programs** block embeds Arduino code alongside the sketch.

## Common Pitfalls & Troubleshooting
- **Part won't connect** → connector `svgId`/`terminalId` mismatch with the SVG.
- **Project won't open** → corrupt `.fzz` zip or missing embedded part; validate
  the inner `.fz` XML.
- **Missing parts on another machine** → you shared `.fz`, not `.fzz`.
- **Gerber export fails** → unrouted nets or DRC violations in PCB view.
- **Slow with big sketches** → too many discrete wires; consolidate with buses.

## Integration Notes
- Sketches are XML — scriptable to *read/transform*, but final render/export is
  GUI-driven.
- Gerbers/Excellon feed standard fab pipelines; SVG/PNG feed docs and tutorials.
- Not a Markdown-native diagram; export SVG/PNG for embedding.

## Best For / Avoid For
`breadboard`, `education`, `arduino`, `maker`, `prototype-to-pcb` — choose
Fritzing for teaching visuals and simple boards where the breadboard picture is
the deliverable. Avoid for dense/multilayer professional boards (use KiCad) and
for schematic *figures* in papers (use CircuiTikZ/SchemDraw).

⌞fritzing⌟

## See Also
- [kicad.md](kicad.md) — professional capture + PCB when you outgrow Fritzing
- [schemdraw.md](schemdraw.md) — code-drawn schematics
- [circuitikz.md](circuitikz.md) — LaTeX schematic figures
- [spice-netlist.md](spice-netlist.md) — simulate the circuit
- ../use-case/engineering-diagrams.md
