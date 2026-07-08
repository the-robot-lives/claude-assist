# nwdiag

## What
nwdiag is a network-diagram generator in the blockdiag family that visualizes network topologies from simple text descriptions. It specializes in multi-subnet layouts with clean, structured output and is consumed via a Python CLI/package.

## How
- The LLM emits nwdiag text markup — an `nwdiag { ... }` block defining `network` segments (with `address` ranges) and the nodes/devices belonging to each, plus shapes like `[shape = cloud]` and inter-node links.
- That markup is turned into a viewable artifact by installing `pip install nwdiag` and rendering the source; devices are automatically grouped by network segment.
- Typical final artifact: PNG (default), SVG, PDF, or PostScript network diagram.

## Why
- Reach for nwdiag when you need purpose-built network-architecture diagrams that handle complex multi-network topologies with simple, maintainable syntax — best for infrastructure documentation, system-administration workflows, and DevOps network planning.
- Limitations: limited control over node positioning, basic styling compared to modern tools, a Python-runtime dependency, and static-only output.
- Relative to its family siblings: nwdiag is the network-topology specialization of the blockdiag engine, distinct from rackdiag (physical racks) and packetdiag (packet layouts).

## Source
- Solution reference: `fim/solution/nwdiag.md`
