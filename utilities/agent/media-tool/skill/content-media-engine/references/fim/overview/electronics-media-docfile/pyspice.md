# PySpice

## What
PySpice is a Python interface to SPICE circuit simulators, bridging Python with Ngspice or Xyce for numeric circuit simulation. It runs in a Python runtime and produces simulation datasets (typically plotted with matplotlib); its consumer is Python code driving a native SPICE backend.

## How
- **LLM emits:** Python code building a `Circuit` from `PySpice.Spice.Netlist`, adding elements with unit-aware helpers (e.g. `circuit.R(1, 1, 2, 1@u_kΩ)`, `circuit.C(1, 2, circuit.gnd, 1@u_uF)`).
- **Render path:** obtain `simulator = circuit.simulator()` and run an analysis such as `simulator.transient(step_time=1@u_us, end_time=100@u_us)`; plot the returned analysis with matplotlib. Requires `pip install PySpice` plus an Ngspice backend (`apt-get install ngspice` / `brew install ngspice`).
- **Typical final artifact:** matplotlib plots of simulation results (waveforms, frequency response).

## Why
- **Reach for it when:** you need full SPICE simulation power (DC/AC/transient/noise, parametric sweeps) driven from Python with unit-aware calculations and matplotlib plotting.
- **Limitations:** requires an Ngspice/Xyce install, assumes SPICE-syntax knowledge, can hit convergence issues, and has a limited built-in component library.
- **Relative to siblings:** PySpice is the numeric-simulation counterpart to Lcapy's symbolic analysis, and it consumes the same SPICE-netlist concepts as the raw `spice-netlist` format but wraps them in a Pythonic, unit-aware API.

## Source
- Solution reference: `fim/solution/pyspice.md`
