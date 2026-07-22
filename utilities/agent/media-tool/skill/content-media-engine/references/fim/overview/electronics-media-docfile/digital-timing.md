# Digital Timing Diagrams

## What
Digital Timing Diagrams is a category of tools and formats for generating protocol and signal timing visualizations (clocks, buses, timing relationships). It is not one library but a family — spanning tikz-timing (LaTeX), WaveDrom, and Python timing tools — whose consumers range from LaTeX toolchains to Python scripts producing SVG/PDF/PNG.

## How
- **LLM emits:** the notation of the chosen backend — e.g. a `tikztimingtable` LaTeX block (`Clock & 10{C} \\`, `Data & 2D{Valid} 2U 3D{New} 3Z \\`) or Python calls (`td.add_signal("CLK", "clock", period=2)`).
- **Render path:** for tikz-timing, compile the LaTeX (`tlmgr install tikz-timing`); for the Python route, build a `TimingDiagram` and call `td.render()`. WaveDrom is the JSON-based option within this family.
- **Typical final artifact:** SVG, PDF, or PNG timing diagrams.

## Why
- **Reach for it when:** you need protocol visualization, bus representations, and annotated timing relationships and want to pick the backend that matches your document toolchain (LaTeX vs. web/JSON vs. Python).
- **Limitations:** tool fragmentation and format incompatibility across the ecosystem, limited standardization, and manual timing entry.
- **Relative to siblings:** this is the umbrella category that WaveDrom and WaveJSON concretize — reach for a specific tool (usually WaveDrom for web/SVG or tikz-timing for LaTeX) rather than "digital-timing" in the abstract when the output toolchain is known.

## Source
- Solution reference: `fim/solution/digital-timing.md`
