# SPICE Netlist

## What
SPICE Netlist is the industry-standard text format for describing circuits to SPICE simulators. It is a plain-text description language (not a renderer); its consumers are SPICE engines such as Ngspice, LTspice, and HSpice, plus Python tooling like `spicelib`/`PyLTSpice`.

## How
- **LLM emits:** SPICE netlist text — element lines (`V1 in 0 DC 5 AC 1`, `R1 in out 1k`, `C1 out 0 100n`), analysis directives (`.ac dec 10 1 100k`, `.tran 0 10m 0 10u`), `.subckt`/`.ends` hierarchical blocks, and `.end`.
- **Render path:** feed the netlist to a simulator (`ngspice`, LTspice) to run the requested analyses; there is no schematic rendering — output is numeric/waveform data from the simulator or a plotting tool.
- **Typical final artifact:** simulation results (waveform/data) from the SPICE engine; the netlist itself is a `.cir`/`.sp` text file.

## Why
- **Reach for it when:** you need a portable, simulator-agnostic circuit description supported by every SPICE tool, with hierarchical subcircuits, parameter sweeps, and Monte Carlo analysis.
- **Limitations:** text-only with no schematic information, error-prone syntax, and manual node numbering.
- **Relative to siblings:** the raw netlist is the substrate that PySpice generates programmatically and that Lcapy borrows for its input syntax — hand-author the netlist for maximum simulator portability, use PySpice when you want a Python API around it.

## Source
- Solution reference: `fim/solution/spice-netlist.md`
