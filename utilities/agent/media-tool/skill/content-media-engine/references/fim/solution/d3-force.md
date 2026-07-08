---
name: D3 Force
description: Force-directed graph layout module for D3.js with customizable physics simulation
docs: https://d3js.org/d3-force
examples: https://observablehq.com/@d3/force-directed-graph
---

# D3 Force — Physics-based network layout

`d3-force` is the velocity-Verlet physics engine inside D3 used to position nodes in network/graph visualizations. It is not a renderer: it computes `x`/`y` (and `vx`/`vy`) for an array of node objects each *tick*, and you draw them (SVG or canvas) yourself. You compose *forces* (charge, links, centering, collision, positioning) onto a `forceSimulation`, and the layout settles as an internal `alpha` cools to zero. This file focuses on the force simulation specifically — for the rest of D3 (scales, selections, shapes) see `d3_js.md`.

**Current Version**: d3-force 3.x (part of d3@7)  **License**: ISC  **Runtime**: browser or Node (headless layout)

## Official Resources & Documentation
- Module docs: https://d3js.org/d3-force
- Repo: https://github.com/d3/d3-force
- Canonical example: https://observablehq.com/@d3/force-directed-graph
- Disjoint graph: https://observablehq.com/@d3/disjoint-force-directed-graph

## Installation & Setup
```bash
npm install d3-force            # just the module
# or the full toolkit:
npm install d3
```
```html
<script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
```
```javascript
import * as d3 from 'd3';                    // d3.forceSimulation, d3.forceLink, ...
// or granular:
import {forceSimulation, forceManyBody, forceLink, forceCenter, forceCollide} from 'd3-force';
```

## Core API Reference
```javascript
const simulation = d3.forceSimulation(nodes)     // nodes: [{id, ...}] mutated in place
  .force('charge', d3.forceManyBody().strength(-300))
  .force('link',   d3.forceLink(links).id(d => d.id).distance(50))
  .force('center', d3.forceCenter(width / 2, height / 2))
  .force('collide', d3.forceCollide().radius(20))
  .on('tick', ticked)                            // called each step
  .on('end', () => console.log('settled'));

function ticked() {
  node.attr('cx', d => d.x).attr('cy', d => d.y);
  link.attr('x1', d => d.source.x).attr('y1', d => d.source.y)
      .attr('x2', d => d.target.x).attr('y2', d => d.target.y);
}
```
`forceSimulation(nodes)` mutates each node object, adding `x`, `y`, `vx`, `vy`, and `index`. `forceLink` replaces string `source`/`target` ids with node object references after the first tick.

## The Forces

### forceManyBody — charge (repulsion/attraction)
N-body force between all nodes. Negative strength repels (spread out), positive attracts (cluster).
```javascript
d3.forceManyBody()
  .strength(-300)              // negative = repel; default -30
  .distanceMin(1)              // clamp near-field to avoid infinite velocity
  .distanceMax(400)            // ignore beyond this range (perf + local layout)
  .theta(0.9)                  // Barnes-Hut approximation accuracy (lower = accurate/slower)
```

### forceLink — springs along edges
Pulls linked nodes toward a target `distance`.
```javascript
d3.forceLink(links)
  .id(d => d.id)               // REQUIRED when links use id strings, not indices
  .distance(50)                // rest length (can be a function of the link)
  .strength(l => 1 / Math.min(count[l.source.id], count[l.target.id]))  // default: 1/min-degree
  .iterations(1)               // relaxation passes per tick (stiffer links)
```

### forceCenter — translate the mean position
Keeps the whole graph centered on `(x, y)`. It moves nodes uniformly; it does not attract them (no strength on positions).
```javascript
d3.forceCenter(width / 2, height / 2).strength(1)   // strength scales the recentering
```

### forceCollide — non-overlap
Prevents node circles from overlapping by resolving as elastic collisions.
```javascript
d3.forceCollide().radius(d => d.r + 2).strength(0.7).iterations(2)
```

### forceX / forceY — positional pull toward an axis/value
Attract nodes toward a target x or y — useful for grouping, disjoint graphs, or replacing `forceCenter`.
```javascript
d3.forceX(width / 2).strength(0.05)
d3.forceY(d => yScale(d.group)).strength(0.2)   // pull by category → swimlanes
```

### forceRadial — pull toward a circle
```javascript
d3.forceRadial(radius, cx, cy).strength(0.8)    // arrange nodes on/around a ring
```

## The alpha cooling schedule (why the layout settles)
The simulation runs while `alpha` (energy) decays from 1 toward `alphaMin`. Understanding these controls is the key to tuning force layouts:
```javascript
simulation
  .alpha(1)              // current energy (reset to reheat)
  .alphaMin(0.001)       // stop when alpha drops below this (~300 ticks default)
  .alphaDecay(0.0228)    // per-tick cooling rate; 1 - (alphaMin)^(1/300). Lower = longer, better layout
  .alphaTarget(0)        // the value alpha decays TOWARD; set >0 to keep it "warm" during drag
  .velocityDecay(0.4);   // friction: fraction of velocity lost per tick (0=frictionless, 1=frozen)
```
- **Reheat on interaction**: `simulation.alphaTarget(0.3).restart()` during a drag, then `alphaTarget(0)` on release.
- **Longer, prettier layouts**: reduce `alphaDecay` (e.g. `0.01`) so it cools slowly.
- **`velocityDecay`** damps oscillation — raise it if the graph jitters/explodes, lower it for more spread.

## Simulation control methods
```javascript
simulation.nodes(nodes);            // (re)set nodes
simulation.force('name', force);    // add/replace; pass null to remove
simulation.tick(n);                 // advance manually (headless/pre-warm)
simulation.restart();               // resume the internal timer
simulation.stop();                  // pause
simulation.find(x, y, radius);      // nearest node to a point (hit-testing)
```

## How-To

### How to render nodes/links and set colors
d3-force positions; you draw. Color by group with a D3 ordinal scale.
```javascript
const color = d3.scaleOrdinal(d3.schemeCategory10);   // or schemeTableau10
const link = svg.append('g').attr('stroke', '#999').attr('stroke-opacity', 0.6)
  .selectAll('line').data(links).join('line')
  .attr('stroke-width', d => Math.sqrt(d.value));
const node = svg.append('g').attr('stroke', '#fff').attr('stroke-width', 1.5)
  .selectAll('circle').data(nodes).join('circle')
  .attr('r', 6)
  .attr('fill', d => color(d.group));                 // <-- color palette by category
```
Palettes come from d3-scale-chromatic: `d3.schemeCategory10`, `d3.schemeTableau10`, `d3.schemeSet2`, or continuous `d3.interpolateViridis` via `d3.scaleSequential`.

### How to add drag interaction
```javascript
node.call(d3.drag()
  .on('start', (e,d) => { if (!e.active) simulation.alphaTarget(0.3).restart(); d.fx=d.x; d.fy=d.y; })
  .on('drag',  (e,d) => { d.fx=e.x; d.fy=e.y; })
  .on('end',   (e,d) => { if (!e.active) simulation.alphaTarget(0); d.fx=null; d.fy=null; }));
```
Setting `d.fx`/`d.fy` *fixes* a node's position (overrides physics); null releases it.

### How to keep a disjoint (multi-component) graph on screen
`forceCenter` alone lets components drift apart. Replace it with positional forces:
```javascript
simulation
  .force('charge', d3.forceManyBody().strength(-200))
  .force('link', d3.forceLink(links).id(d => d.id))
  .force('x', d3.forceX())
  .force('y', d3.forceY());
```

### How to run the layout headless (server / pre-computed positions)
```javascript
const sim = d3.forceSimulation(nodes)
  .force('charge', d3.forceManyBody())
  .force('link', d3.forceLink(links).id(d => d.id))
  .stop();
for (let i = 0; i < 300; i++) sim.tick();   // settle without rendering
// nodes now have final x/y — serialize or draw once
```

### How to render 10k+ nodes with canvas
```javascript
const ctx = canvas.getContext('2d');
simulation.on('tick', () => {
  ctx.clearRect(0, 0, width, height);
  ctx.strokeStyle = '#ccc';
  for (const l of links) { ctx.beginPath(); ctx.moveTo(l.source.x,l.source.y); ctx.lineTo(l.target.x,l.target.y); ctx.stroke(); }
  for (const n of nodes) { ctx.beginPath(); ctx.arc(n.x,n.y,5,0,2*Math.PI); ctx.fillStyle=color(n.group); ctx.fill(); }
});
```

## Do's and Don'ts

### ✅ Do
- Call `.id(d => d.id)` on `forceLink` whenever links reference string ids — omitting it treats source/target as array indices.
- Reheat with `alphaTarget(0.3).restart()` during interaction, and return to `alphaTarget(0)` after.
- Switch to `<canvas>` past a few thousand nodes; SVG DOM churn dominates otherwise.
- Tune `charge.strength`, `link.distance`, and `velocityDecay` together — they interact.

### ❌ Don't
- Don't expect d3-force to draw anything — it only computes coordinates.
- Don't forget `distanceMax` on `forceManyBody` for large graphs; without it, all-pairs charge is O(n log n) but constants hurt.
- Don't set `velocityDecay` to 0 with strong charge — the graph oscillates/explodes off-screen.
- Don't mutate `nodes`/`links` arrays without calling `simulation.nodes(...)`/`force.links(...)` again.
- Don't leave the simulation running forever — it stops at `alphaMin`; re-`restart()` only when data/interaction changes.

## Styling, Theming & Customization
- All visual styling is your rendering code — stroke, fill (ordinal color scale), radius (by degree/metric), opacity by weight.
- Label nodes with `<text>` (SVG) or `ctx.fillText` (canvas) in the tick handler; beware label overplotting.
- Encode edge weight as `stroke-width`, node importance as `r` (e.g. `d3.scaleSqrt` on degree).

## Common Pitfalls & Troubleshooting
- Nodes fly off-screen → charge too strong / friction too low; raise `velocityDecay`, add `forceX/Y` or `forceCenter`.
- Layout collapses to a point → missing repulsion (`forceManyBody` negative strength) or links too strong.
- Links don't connect → `forceLink.id` not set, so string ids never resolve to nodes.
- Graph never settles / keeps twitching → `alphaTarget` stuck above 0 after a drag; reset to 0.
- Poor perf → too many SVG nodes (switch to canvas), no `distanceMax`, or `theta` too low.

## Best For / Avoid For
`network-graphs`, `node-link-diagrams`, `relationship-maps`, `data-journalism`, `animated-graph-transitions`, `custom-layouts` — choose d3-force.
Avoid for: `standard-charts` (Chart.js/Plot), `turnkey-graph-UI` (Cytoscape.js/Sigma.js — includes rendering + interaction), `no-D3-budget`.

## See Also
- `d3_js.md` — the full D3 toolkit (scales, selections, shapes, drag)
- `cytoscape_js.md` / `sigma_js.md` — batteries-included graph libraries with rendering
- `../use-case/network-graph.md`
