# rackdiag

## What
rackdiag is a server-rack-diagram generator in the blockdiag suite that visualizes datacenter infrastructure and rack layouts from text descriptions, with proper U-unit positioning and equipment representation. It is consumed via a Python CLI/package.

## How
- The LLM emits rackdiag text markup — a `rackdiag { ... }` block placing equipment at U-positions (e.g. `1U: Load Balancer [42U]`), setting `rack_height`/`rack_unit`, and applying per-item `color` styling.
- That markup is turned into a viewable artifact via `pip install rackdiag` and the CLI, e.g. `rackdiag diagram.rack -f PNG`.
- Typical final artifact: SVG, PNG, or PDF rack diagram with accurate rack-unit sizing.

## Why
- Reach for rackdiag when you need precise rack-unit-accurate datacenter and server-rack diagrams with predefined equipment styling — best for infrastructure documentation, datacenter planning, server-deployment layouts, and capacity planning.
- Limitations: narrow scope (rack diagrams only), text-based with no interactive/real-time editing, basic styling, and requires understanding rack-unit conventions.
- Relative to its family siblings: rackdiag is the physical-rack specialization of the blockdiag engine, complementary to nwdiag (logical network topology).

## Source
- Solution reference: `fim/solution/rackdiag.md`
