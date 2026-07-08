# Blockdiag

## What
Blockdiag is a simple block-diagram generator that builds box-and-arrow diagrams from text descriptions. It is the root of the blockdiag family of Python tools and is consumed via a Python CLI/package, emitting multiple raster and vector output formats.

## How
- The LLM emits blockdiag text markup — a `blockdiag { ... }` block defining labeled nodes, `->` relationships, and `group { ... }` clusters.
- That markup is turned into a viewable artifact by installing via `pip install blockdiag` (with `blockdiag[pdf]` for PDF support) and rendering the `.diag` source; the suite's siblings (actdiag, nwdiag, seqdiag) install alongside it.
- Typical final artifact: PNG, SVG, or PDF block diagram with automatic layout and spacing.

## Why
- Reach for blockdiag when you want minimal, intuitive syntax with automatic layout and built-in shapes/groups — best for `system-architecture`, `network-topology`, `component-diagrams`, `simple-workflows`, and `infrastructure-maps`.
- Limitations: limited styling customization, basic layout algorithms only, no advanced positioning control, restricted to block/box diagrams, and less active development.
- Relative to its family siblings: blockdiag is the generic block-diagram base; actdiag (activity), nwdiag (network), seqdiag (sequence), packetdiag (packets), and rackdiag (racks) specialize the same engine for specific diagram types.

## Source
- Solution reference: `fim/solution/blockdiag.md`
