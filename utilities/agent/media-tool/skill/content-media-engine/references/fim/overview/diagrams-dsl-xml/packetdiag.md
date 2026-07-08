# packetdiag

## What
packetdiag is a Python-based network-protocol packet-diagram generator in the blockdiag suite that produces bit-level-precise packet-format diagrams. It transforms text protocol descriptions into publication-ready visuals for RFCs, technical documentation, and educational materials, and is consumed via a CLI or a Python API.

## How
- The LLM emits packetdiag text markup — a `packetdiag { ... }` block assigning bit ranges to field labels (e.g. `0-15: Source Port`, `16-31: Destination Port`).
- That markup is turned into a viewable artifact via `pip install packetdiag` (extras `[pdf]`, `[svg]`, `[all]`) and the CLI, e.g. `packetdiag -T svg diagram.diag`, with options for DPI, size, and custom fonts; a Python API (`parse_string` + `DiagramDraw`) supports programmatic generation.
- Typical final artifact: PNG (default), SVG, PDF, or EPS packet-structure diagram; licensed under Apache 2.0.

## Why
- Reach for packetdiag when you need accurate, standards-grade packet/protocol structure diagrams with bit-level precision — best for RFC and protocol documentation, networking education (e.g. CCNA/CCNP materials), and system-design/security documentation.
- Limitations: packetdiag-specific syntax to learn and protocol/binary knowledge assumed, limited layout flexibility versus GUI tools, static output only (no interactivity/animation), text-and-basic-shapes only (no icons), and notable memory use on large diagrams.
- Relative to its family siblings: packetdiag is the packet/protocol specialization of the blockdiag engine — a narrow technical niche distinct from nwdiag (topologies) and rackdiag (racks).

## Source
- Solution reference: `fim/solution/packetdiag.md`
