# nwdiag — Network topology diagram generator from text

nwdiag renders network topology diagrams from a compact text grammar: you declare networks (subnets) with an address range and the nodes attached to them, and nwdiag lays out the subnet bars and node boxes automatically. A single node can attach to several networks (multi-homing / peering). It is part of the *blockdiag family* and shares its `{ }` block grammar. The `nwdiag` package also bundles **rackdiag** and **packetdiag**. Output is PNG, SVG, or PDF via a Python CLI.

**Current Version**: nwdiag 3.x (3.0.0+)  **License**: Apache 2.0  **Runtime**: Python 3.7+ CLI (no browser)

## Official Resources & Documentation
- Home / docs: http://blockdiag.com/en/nwdiag/
- Examples: http://blockdiag.com/en/nwdiag/examples.html
- GitHub: https://github.com/blockdiag/nwdiag
- PyPI: https://pypi.org/project/nwdiag/
- Sphinx extension: https://pypi.org/project/sphinxcontrib-nwdiag/

## Installation & Setup
```bash
pip install nwdiag                     # bundles nwdiag, rackdiag, packetdiag
pip install "nwdiag[pdf]"              # reportlab-backed PDF output
pip install sphinxcontrib-nwdiag       # Sphinx directives
```
CLI rendering (note the command is `nwdiag`, not `blockdiag`):
```bash
nwdiag net.diag                        # -> net.png
nwdiag net.diag -T svg -o net.svg      # SVG
nwdiag net.diag -T pdf -o net.pdf      # PDF (needs [pdf] extra)
nwdiag -f /path/Font.ttf net.diag      # embed a TTF for non-ASCII labels
```

## Shared blockdiag-family Grammar
nwdiag wraps its body in `nwdiag { … }`. These constructs are common to the whole family; nwdiag-specific `network` syntax follows.

**Comments**: `// line` and `# line`.

**Diagram-level attributes**: `default_shape`, `default_node_color`, `default_group_color`, `default_fontsize`, `default_textcolor`, `node_width`, `node_height`, `span_width`, `span_height`, `orientation` (`portrait` | `landscape`).

**Node attributes** — `name [attr = value];`: `label`, `shape` (`box`, `cloud`, `ellipse`, etc.), `color`, `style` (`dashed`/`dotted`/`solid`/`"3,3"`), `stacked`, `numbered`, `icon` (PNG path), `textcolor`, `width`, `height`, `fontsize`, plus the network-specific `address`.

**Edge/peer attributes** — `A -- B [attr = value];`: `label`, `color`, `style` (`dashed`/`dotted`), `thick`. (nwdiag peering links use the undirected `--` connector, not `->`.)

**Groups** cluster nodes logically (orthogonal to networks):
```nwdiag
nwdiag {
  group {
    label = "Web Tier"; color = "#e8f0fe";
    web01; web02;
  }
  network dmz { web01; web02; }
}
```
**Classes** bundle reusable attributes: `class db [color = "#fce5cd", style = dashed];` then `node [class = "db"]`.

## Core Syntax / nwdiag Networks
A `network` block declares a subnet. Its `address` sets the subnet range; each member node may set its own host `address`, which nwdiag prints on the connecting line.

```nwdiag
nwdiag {
  network dmz {
    address = "210.0.0.0/24";
    web01 [address = "210.0.0.1"];
    web02 [address = "210.0.0.2"];
  }
  network internal {
    address = "192.168.0.0/24";
    web01 [address = "192.168.0.1"];   // web01 spans dmz + internal
    web02 [address = "192.168.0.2"];
    db01  [address = "192.168.0.10"];
  }
}
```
A node listed inside two `network` blocks is **multi-homed** — nwdiag draws it once and connects it to both subnet bars. This is the idiomatic way to show a firewall, router, or dual-NIC host bridging segments.

**Network attributes** (inside a `network { }`):
| attr | note |
|------|------|
| `address` | subnet CIDR or label, e.g. `"192.168.0.0/24"` |
| `color` | fill of the subnet bar |
| `label` | override the network's displayed name |

```nwdiag
nwdiag {
  network mgmt {
    address = "10.0.0.0/24";
    color = "#e6f4ea";
    label = "Management LAN";
    switch [address = "10.0.0.1"];
    monitor [address = "10.0.0.9"];
  }
}
```

**Router / internet idiom** — attach an off-subnet cloud and a router with peer links:
```nwdiag
nwdiag {
  inet [shape = cloud];
  inet -- router;                      // peer link, undirected

  network dmz {
    address = "210.0.0.0/24";
    router  [address = "210.0.0.1"];
    web01   [address = "210.0.0.2"];
  }
  network internal {
    address = "192.168.0.0/24";
    router  [address = "192.168.0.1"]; // router bridges dmz + internal
    db01    [address = "192.168.0.10"];
  }
}
```

**Peer connections** between two nodes not sharing a drawn subnet use `--`:
```nwdiag
nwdiag {
  network a { router1; }
  network b { router2; }
  router1 -- router2 [label = "VPN", style = dashed];
}
```

**Multiple stacked networks** simply stack in declaration order; a shared node threads them vertically:
```nwdiag
nwdiag {
  network frontend { address = "203.0.113.0/24"; lb [address = ".1"]; web [address = ".2"]; }
  network app      { address = "10.1.0.0/24";     web [address = ".2"]; app1 [address = ".3"]; }
  network data     { address = "10.2.0.0/24";     app1 [address = ".3"]; db [address = ".4"]; }
}
```
Short host forms like `[address = ".1"]` are accepted and rendered against the network's CIDR.

## Diagram / Output Types
nwdiag focuses on **layer-2/3 network topology**: subnets, VLANs, DMZ/internal/management tiers, multi-homed routers and firewalls, VPN peers, and internet edges. For the physical rack view of the same gear use rackdiag; for packet-field layouts use packetdiag (both ship in this package).

## How-To

### How to add colors, styling & themes
Theme via diagram `default_*` attributes, per-`network` `color`, per-node `color`, and reusable `class` bundles.
```nwdiag
nwdiag {
  default_node_color = "#eef2ff";
  default_textcolor = "#1a1a2e";
  default_fontsize = 11;

  class secure [color = "#f4cccc", style = dashed];

  network dmz {
    address = "210.0.0.0/24";
    color = "#fff2cc";                 // tint the subnet bar
    fw   [address = "210.0.0.1", class = "secure"];
    web  [address = "210.0.0.2", color = "#d9ead3"];
  }
  network internal {
    address = "192.168.0.0/24";
    color = "#e6f4ea";
    fw  [address = "192.168.0.1"];
    db  [address = "192.168.0.10", shape = cloud];
  }
  fw -- web [color = "#4a86e8", thick];
}
```
Colors accept CSS names or `#rrggbb`.

### How to model a firewall bridging two subnets
Declare the same node in both networks with its per-subnet address — nwdiag merges it into one multi-homed box.
```nwdiag
nwdiag {
  network external { address = "203.0.113.0/24"; fw [address = "203.0.113.1"]; }
  network internal { address = "10.0.0.0/24";    fw [address = "10.0.0.1"]; host [address = "10.0.0.5"]; }
}
```

### How to group nodes independently of their subnet
`group { }` draws a logical cluster (e.g., "Web Tier") across whatever networks the members sit in.
```nwdiag
nwdiag {
  group {
    label = "App Cluster"; color = "#e8f0fe";
    app1; app2;
  }
  network app { address = "10.1.0.0/24"; app1 [address = ".1"]; app2 [address = ".2"]; lb [address = ".9"]; }
}
```

### How to connect to the internet edge / cloud
```nwdiag
nwdiag {
  internet [shape = cloud];
  internet -- edge_router;
  network dmz { address = "198.51.100.0/24"; edge_router [address = ".1"]; proxy [address = ".2"]; }
}
```

## Do's and Don'ts

### ✅ Do
- Quote CIDR/address strings — `address = "192.168.0.0/24"`.
- Reuse a node name across `network` blocks to express multi-homing; that is the core nwdiag idiom.
- Use `--` (not `->`) for peer links; nwdiag topology is undirected.
- Tint each subnet with `color` to separate tiers visually.
- Keep the tool command straight: run `nwdiag`, not `blockdiag`, on a `.diag` file.

### ❌ Don't
- Don't use directed `A -> B` edges — nwdiag expects `--` peer connectors between nodes.
- Don't declare two unrelated nodes with the same name expecting two boxes — same name = same (multi-homed) node.
- Don't omit the `network`'s `address` if you print host addresses; hosts render against the subnet CIDR.
- Don't nest `network` blocks inside each other — networks are siblings; use `group` for logical nesting.
- Don't rely on layout order for meaning beyond vertical stacking; there is no manual positioning.

## Styling, Theming & Customization
Theming lives in the diagram body: `default_*` attributes set the baseline, `network { color = … }` tints subnet bars, node `color`/`shape`/`icon` style individual devices, and `class` factors shared looks. Use `icon = "router.png"` to brand devices with vendor glyphs. There is no external theme file.

## Advanced Features
- **Bundled tools**: the same `pip install nwdiag` gives you `rackdiag` and `packetdiag` commands.
- **Node icons**: `shape = cloud` for internet, plus `icon = "*.png"` for device art.
- **Groups vs networks**: `group` is logical (colored cluster), `network` is a subnet bar — they compose freely.
- **Sphinx**: `.. nwdiag::` directive renders inline in docs.

## Common Pitfalls & Troubleshooting
- **Node duplicated instead of bridged**: check the name matches exactly in both `network` blocks (case-sensitive).
- **Addresses not showing**: give each member an `address` and the `network` an `address`.
- **`->` parse error / odd layout**: switch to `--` for peer links.
- **PDF fails**: install `"nwdiag[pdf]"`.
- **Non-ASCII labels are boxes**: pass `-f /path/Font.ttf`.

## Integration Notes
- **Sphinx**: `sphinxcontrib-nwdiag` provides the `.. nwdiag::` directive (plus `rackdiag`/`packetdiag` directives from the same package).
- **Kroki**: https://kroki.io renders nwdiag server-side — POST the source to `https://kroki.io/nwdiag/svg` with no local install.
- **MkDocs / Markdown**: embed via the `mkdocs-kroki-plugin` or a Kroki fenced block.
- **CI**: `.diag` sources diff cleanly; render to SVG in a build step or via Kroki on demand.

## Best For / Avoid For
`network-topology`, `subnet-maps`, `dmz-diagrams`, `vpn-peering`, `infrastructure-docs` — choose nwdiag when you need clean subnet-and-host topology from text. Avoid for physical rack elevation (use rackdiag), packet byte layouts (packetdiag), or free-form graphs (graphviz/mermaid).

## See Also
- Family siblings: `blockdiag.md` (core blocks/flow), `rackdiag.md` (server racks), `packetdiag.md` (packet fields), `seqdiag.md` (sequence), `actdiag.md` (activity)
- Alternatives: `mermaid.md` (Markdown diagrams), `graphviz.md` (DOT graph layout)
- Use cases: `../use-case/networks-graphs.md`, `../use-case/diagram-generation.md`
