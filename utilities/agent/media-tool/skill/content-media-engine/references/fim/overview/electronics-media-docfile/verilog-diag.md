# Verilog Diagrams

## What
Verilog Diagrams is a toolchain approach for visualizing Verilog/SystemVerilog hardware descriptions — converting RTL into schematics, hierarchy views, and dataflow graphs. It combines synthesis and rendering tools (Yosys, netlistsvg, pyverilog) whose consumers are command-line pipelines and Python scripts producing SVG/DOT output.

## How
- **LLM emits:** Verilog/SystemVerilog source plus the pipeline commands to visualize it. The canonical flow: `yosys -p "read_verilog design.v; proc; opt; write_json design.json"` then `netlistsvg design.json -o design.svg`.
- **Render path:** synthesize the RTL to a JSON netlist with Yosys, then render with netlistsvg; alternatively use pyverilog's `VerilogDataflowAnalyzer` to `draw_graph("output.svg")`. Install via `apt-get install yosys`, `npm install -g netlistsvg`, `pip install pyverilog`.
- **Typical final artifact:** SVG, DOT, or JSON (hierarchy, FSM, and dataflow views).

## Why
- **Reach for it when:** you have RTL and need automatically-laid-out schematic, hierarchy, state-machine, or dataflow visualizations of the design.
- **Limitations:** complex designs become cluttered, customization is limited, the multi-tool chain adds complexity, and synthesis is required before visualization.
- **Relative to siblings:** verilog-diag renders *structure* from HDL, whereas WaveDrom/digital-timing render *behavior over time* — use verilog-diag for the circuit graph, WaveDrom for the timing waveforms (the two are often paired, and this pipeline can feed WaveDrom for timing).

## Source
- Solution reference: `fim/solution/verilog-diag.md`
