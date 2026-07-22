# blockdiag — Block / flow diagram generator from text

blockdiag renders simple block (box-and-arrow) diagrams from a compact text grammar. It performs automatic layout: you declare nodes and edges, it places and routes them. It is the root of the *blockdiag family* (blockdiag, nwdiag, rackdiag, packetdiag, seqdiag, actdiag) — all sharing one `{ }` block grammar. Output is PNG, SVG, or PDF. It runs as a Python CLI and as Sphinx directives.

**Current Version**: blockdiag 3.x (3.0.0+)  **License**: Apache 2.0  **Runtime**: Python 3.7+ CLI (no browser)

## Official Resources & Documentation
- Home / docs: http://blockdiag.com/en/blockdiag/
- Grammar & examples: http://blockdiag.com/en/blockdiag/examples.html
- Interactive editor: http://interactive.blockdiag.com/
- GitHub: https://github.com/blockdiag/blockdiag
- PyPI: https://pypi.org/project/blockdiag/
- Sphinx extension: https://pypi.org/project/sphinxcontrib-blockdiag/

## Installation & Setup
```bash
# core tool + the whole family
pip install blockdiag nwdiag seqdiag actdiag
pip install "blockdiag[pdf]"          # reportlab-backed PDF output
# Sphinx integration
pip install sphinxcontrib-blockdiag
```
CLI rendering:
```bash
blockdiag foo.diag                    # -> foo.png (default)
blockdiag foo.diag -T svg -o out.svg  # SVG
blockdiag foo.diag -T pdf -o out.pdf  # PDF (needs [pdf] extra)
blockdiag -f /path/to/Font.ttf foo.diag   # embed a TTF for non-ASCII labels
```
Sphinx usage (in `conf.py` add `sphinxcontrib.blockdiag` to `extensions`):
```rst
.. blockdiag::

   blockdiag { A -> B -> C; }
```

## Shared blockdiag-family Grammar
Every family tool wraps its body in a named block (`blockdiag { … }`). These constructs are common across the family; blockdiag-specific shapes/attributes follow below.

**Comments**: `// line` and `# line` are both accepted.

**Diagram-level attributes** (set once, at the top of the block):
```blockdiag
blockdiag {
  default_shape = roundedbox;   // shape when a node omits shape=
  default_node_color = "#e8f0fe";
  default_group_color = "#f5f5f5";
  default_fontsize = 11;
  default_textcolor = "#222222";
  node_width = 128;             // default node box width (px)
  node_height = 40;             // default node box height (px)
  span_width = 64;              // horizontal gap between columns
  span_height = 40;             // vertical gap between rows
  orientation = portrait;       // portrait (top-down) | landscape (left-right, default)
  A -> B;
}
```

**Node attributes** — `name [attr = value, ...];`
| attr | values | note |
|------|--------|------|
| `label` | quoted string | display text; `\n` for line breaks |
| `shape` | see shape list | node glyph |
| `color` | name or `#rrggbb` | fill color |
| `style` | `dashed` / `dotted` / `solid` / `"3,3"` | border; `"3,3"` is a custom dash pattern |
| `stacked` | (flag) | draw as a stack of sheets |
| `numbered` | int | small badge in the node corner |
| `icon` | `"path.png"` | PNG icon drawn inside the node |
| `textcolor` | color | label color |
| `width` / `height` | px | override per node |
| `fontsize` | int | per-node font size |
| `group` | group name | assign node to a group |

**Edge attributes** — `A -> B [attr = value];`
| attr | values | note |
|------|--------|------|
| `label` | quoted string | edge caption |
| `color` | color | line color |
| `style` | `dashed` / `dotted` / `"3,3"` | line style |
| `dir` | `none` / `forward` / `back` / `both` | arrowhead direction |
| `thick` | (flag) | bold line |
| `folded` | (flag) | force the edge onto a new rank (breaks a row) |
| `hstyle` | `generalization` | hollow-triangle (UML-ish) head |

**Groups** cluster nodes into a labeled box:
```blockdiag
blockdiag {
  group {
    label = "Backend";
    color = "#eef7ff";
    shape = line;     // line = borderless lane instead of a filled box
    web; db;
  }
  web -> db;
}
```
**Classes** define reusable attribute bundles, applied via `class = "name"`:
```blockdiag
blockdiag {
  class emphasis [color = "#ffd966", style = dashed];
  A [class = "emphasis"];
  B [class = "emphasis"];
  A -> B;
}
```

## Core Syntax / blockdiag Node Shapes
blockdiag ships a broad shape set. Set per node with `shape = <name>`.

**General shapes**: `box` (default), `roundedbox`, `diamond`, `minidiamond` (a.k.a. `square`), `circle`, `ellipse`, `note`, `cloud`, `mail`, `actor`, `beginpoint`, `endpoint`.

**Flowchart shapes** (namespaced under `flowchart.`): `flowchart.condition` (decision), `flowchart.database`, `flowchart.terminator`, `flowchart.input`, `flowchart.loopin`, `flowchart.loopout`.

```blockdiag
blockdiag {
  start   [shape = beginpoint];
  proc    [shape = box, label = "Process"];
  choice  [shape = flowchart.condition, label = "OK?"];
  store   [shape = flowchart.database, label = "DB"];
  form    [shape = flowchart.input, label = "User Input"];
  stop    [shape = endpoint];

  start -> form -> proc -> choice;
  choice -> store [label = "yes"];
  choice -> stop  [label = "no", style = dashed];
}
```

**Stacked & numbered nodes**:
```blockdiag
blockdiag {
  cache [stacked, label = "Cache Shards"];   // sheet stack
  step  [numbered = 1, label = "First"];      // corner badge "1"
  cache -> step;
}
```

**Edge direction & style spectrum**:
```blockdiag
blockdiag {
  A -> B [label = "sync", dir = forward];
  B -> C [label = "peer", dir = both, thick];
  C -> D [label = "optional", style = dotted, dir = none];
  D -> E [hstyle = generalization];   // UML hollow triangle
}
```

## Diagram / Output Types
blockdiag itself produces: system architecture blocks, component/service maps, flowcharts (via the `flowchart.*` shapes), simple swimlane-like groups, and infrastructure block maps. For sequence, activity, network, rack, or packet diagrams, use the family sibling (see **See Also**).

## How-To

### How to add colors, styling & themes
Set diagram defaults, then override per node/edge, and factor repeated looks into a `class`.
```blockdiag
blockdiag {
  default_shape = roundedbox;
  default_node_color = "#eef2ff";
  default_textcolor = "#1a1a2e";
  default_fontsize = 11;

  class hot  [color = "#ffcccc", style = dashed];
  class cool [color = "#cce5ff"];

  web  [label = "Web", class = "cool"];
  api  [label = "API", color = "#d9ead3"];       // one-off inline color
  db   [shape = flowchart.database, class = "hot"];

  web -> api [color = "#4a86e8", thick];
  api -> db  [label = "SQL", color = "#999999", style = dotted];
}
```
Colors accept CSS names (`orange`, `lightblue`) or hex (`#rrggbb`). `style = "3,3"` gives a custom dash length.

### How to build a flowchart with a decision branch
```blockdiag
blockdiag {
  orientation = portrait;
  begin  [shape = beginpoint];
  recv   [label = "Receive request", shape = flowchart.input];
  valid  [label = "Valid?", shape = flowchart.condition];
  ok     [label = "Handle"];
  err    [label = "Reject", color = "#f4cccc"];
  done   [shape = endpoint];

  begin -> recv -> valid;
  valid -> ok  [label = "yes"];
  valid -> err [label = "no"];
  ok -> done;
  err -> done;
}
```

### How to group nodes into lanes / clusters
```blockdiag
blockdiag {
  group frontend {
    label = "Frontend"; color = "#e8f0fe";
    browser; cdn;
  }
  group backend {
    label = "Backend"; color = "#e6f4ea";
    api; worker; db;
  }
  browser -> cdn -> api -> worker -> db;
}
```
Use `shape = line` inside a group for a borderless swimlane look.

### How to switch layout direction (portrait vs landscape)
```blockdiag
blockdiag {
  orientation = portrait;   // top-to-bottom flow; omit or use landscape for left-to-right
  ingest -> transform -> load -> report;
}
```
`landscape` (the default) flows left→right; `portrait` flows top→bottom.

### How to stack and number a pipeline
```blockdiag
blockdiag {
  shard  [stacked, label = "Shards (x8)"];
  s1 [numbered = 1, label = "Extract"];
  s2 [numbered = 2, label = "Load"];
  s1 -> s2 -> shard;
}
```

## Do's and Don'ts

### ✅ Do
- Quote any multi-word or special-char label — `A [label = "Web Server"];`. Bare multi-word text breaks the parser.
- Declare diagram defaults first so every node inherits a consistent theme.
- Use `class` for repeated styling instead of pasting the same attrs onto many nodes.
- Let a node appear implicitly from an edge (`A -> B;` auto-creates `A` and `B`); only declare a node separately when it needs attributes.
- Use `folded` on an edge to force a wrap when a row grows too wide.

### ❌ Don't
- Don't invent shapes — blockdiag rejects unknown `shape` names. Stick to the listed set; `flowchart.*` shapes require the `flowchart.` prefix.
- Don't expect manual coordinates — layout is automatic; there is no `x=/y=` positioning.
- Don't reuse a node name for two different boxes; the same name always refers to one node.
- Don't put `;` after the closing `}` of a group or the diagram — it is not needed and some builds error.
- Don't rely on CSS-only names for PDF output fonts; embed a TTF with `-f` when using non-Latin labels.

## Styling, Theming & Customization
There is no separate theme file — theming is done through diagram-level `default_*` attributes plus `class` bundles. Common recipe: set `default_node_color`, `default_textcolor`, `default_fontsize`, `default_shape` once, then define 2–3 semantic classes (`hot`, `cool`, `neutral`) and tag nodes. Icons (`icon = "logo.png"`) let you brand nodes with product logos; the PNG is drawn scaled into the node box.

## Advanced Features
- **Icons**: `node [icon = "aws-ec2.png"];` embeds a PNG glyph — pairs well with `label` for infra maps.
- **Custom dash patterns**: `style = "3,3"` (3px dash, 3px gap); larger numbers = longer dashes.
- **`hstyle = generalization`**: hollow-triangle arrowheads for lightweight UML-style inheritance.
- **Sphinx**: the `.. blockdiag::` directive renders inline in docs and supports `:caption:` and per-build formats.

## Common Pitfalls & Troubleshooting
- **Blank / clipped output**: usually an unquoted multi-word label — quote it.
- **"Font not found" or boxes for non-ASCII**: pass `-f /path/Font.ttf`; the default font is Latin-only.
- **Unexpected wrapping**: wide diagrams auto-wrap; use `orientation` and `folded` to control ranks.
- **PDF fails**: install the `[pdf]` extra (`pip install "blockdiag[pdf]"`) — reportlab is required.
- **Group not boxing nodes**: ensure the node names inside the `group { }` exactly match the edge names.

## Integration Notes
- **Sphinx**: `sphinxcontrib-blockdiag` provides the `.. blockdiag::` directive; set output format with `blockdiag_html_image_format = 'SVG'` in `conf.py`.
- **Kroki**: https://kroki.io renders the entire blockdiag family server-side — POST the `.diag` source to `https://kroki.io/blockdiag/svg` (or PNG) with no local Python install. Handy when the FIM agent emits source but the host lacks the CLI.
- **MkDocs / Markdown**: use the `mkdocs-kroki-plugin` or a Kroki fenced block to embed source directly in docs.
- **CI**: `.diag` files are plain text and diff cleanly; render in a build step and commit the SVG, or render on the fly via Kroki.

## Best For / Avoid For
`system-architecture`, `component-maps`, `flowcharts`, `infrastructure-blocks`, `simple-workflows` — choose blockdiag when you want automatic, tidy box-and-arrow layout from plain text. Avoid for rich UML, precise manual layout, interactive/animated diagrams, or dense graphs with hundreds of nodes (use graphviz/mermaid instead).

## See Also
- Family siblings: `nwdiag.md` (networks), `rackdiag.md` (server racks), `packetdiag.md` (packet fields), `seqdiag.md` (sequence), `actdiag.md` (activity/swimlanes)
- Alternatives: `mermaid.md` (flowchart/sequence/class in Markdown), `graphviz.md` (DOT, fine-grained graph layout)
- Use cases: `../use-case/diagram-generation.md`, `../use-case/networks-graphs.md`
