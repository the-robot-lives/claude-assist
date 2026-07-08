# actdiag — Activity diagram (swimlane) generator from text

actdiag renders activity/process-flow diagrams with swimlanes from a compact text grammar: you list the activity flow (`A -> B -> C`) and assign activities to `lane` blocks, and actdiag lays out the lanes and routes the transitions automatically. It is part of the *blockdiag family* and shares its `{ }` block grammar. Output is PNG, SVG, or PDF via a Python CLI.

**Current Version**: actdiag 3.x (3.0.0+)  **License**: Apache 2.0  **Runtime**: Python 3.7+ CLI (no browser)

## Official Resources & Documentation
- Home / docs: http://blockdiag.com/en/actdiag/
- Examples: http://blockdiag.com/en/actdiag/examples.html
- GitHub: https://github.com/blockdiag/actdiag
- PyPI: https://pypi.org/project/actdiag/
- Sphinx extension: https://pypi.org/project/sphinxcontrib-actdiag/

## Installation & Setup
```bash
pip install actdiag
pip install "actdiag[pdf]"             # reportlab-backed PDF output
pip install sphinxcontrib-actdiag      # Sphinx directives
```
CLI rendering (command is `actdiag`):
```bash
actdiag flow.diag                      # -> flow.png
actdiag flow.diag -T svg -o flow.svg   # SVG
actdiag flow.diag -T pdf -o flow.pdf   # PDF (needs [pdf] extra)
actdiag -f /path/Font.ttf flow.diag    # embed a TTF for non-ASCII labels
```

## Shared blockdiag-family Grammar
actdiag wraps its body in `actdiag { … }`. These constructs are common to the whole family; actdiag-specific `lane` syntax follows.

**Comments**: `// line` and `# line`.

**Diagram-level attributes**: `default_shape`, `default_node_color`, `default_group_color`, `default_fontsize`, `default_textcolor`, `node_width`, `node_height`, `span_width`, `span_height`, `orientation` (`portrait` | `landscape`).

**Node (activity) attributes** — `name [attr = value];`: `label`, `shape` (`box`, `roundedbox`, `diamond`, `circle`, `note`, `beginpoint`, `endpoint`, etc.), `color`, `style` (`dashed`/`dotted`/`solid`/`"3,3"`), `textcolor`, `width`, `height`, `fontsize`, `numbered`, `stacked`, `icon` (PNG path).

**Edge (transition) attributes** — `A -> B [attr = value];`: `label`, `color`, `style` (`dashed`/`dotted`), `dir` (`none`/`forward`/`back`/`both`), `thick`, `folded`.

**Classes** bundle reusable attributes: `class io [color = "#fff2cc"];` then `node [class = "io"]`.

## Core Syntax / actdiag Lanes
The distinguishing feature is the **swimlane**. Declare the overall flow with edges, then group activities into `lane` blocks. Each lane is a labeled vertical (or horizontal) band; every activity belongs to exactly one lane, and transitions may cross lanes freely.

```actdiag
actdiag {
  A -> B -> C -> D;

  lane user {
    label = "User";
    A [label = "Login"];
    B [label = "Select Item"];
  }
  lane system {
    label = "System";
    C [label = "Process Order"];
    D [label = "Send Email"];
  }
}
```
Edges are declared once (often before the lanes); the lanes only decide *which band* each node sits in. A transition like `B -> C` naturally crosses from the `user` lane to the `system` lane.

**Cross-lane transitions & branching**:
```actdiag
actdiag {
  start -> pick -> check;
  check -> ship;
  check -> reject;
  ship -> done;
  reject -> done;

  lane customer {
    label = "Customer";
    start [label = "Start", shape = beginpoint];
    pick  [label = "Add to Cart"];
    done  [label = "End", shape = endpoint];
  }
  lane fulfillment {
    label = "Fulfillment";
    check  [label = "In Stock?", shape = diamond];
    ship   [label = "Ship Order"];
    reject [label = "Backorder", color = "#f4cccc"];
  }
}
```

**Lane attributes** — a `lane` accepts `label` (its band caption) and `color` (band tint):
```actdiag
actdiag {
  A -> B;
  lane ops {
    label = "Operations";
    color = "#e6f4ea";
    A [label = "Deploy"];
    B [label = "Monitor"];
  }
}
```

**Decision points** use `shape = diamond`; **start/end** use `beginpoint`/`endpoint`:
```actdiag
actdiag {
  s -> q -> a;
  q -> b;
  lane flow {
    label = "Review";
    s [shape = beginpoint];
    q [label = "Approved?", shape = diamond];
    a [label = "Publish"];
    b [label = "Revise", style = dashed];
  }
}
```

## Diagram / Output Types
actdiag draws **activity / process-flow diagrams with swimlanes**: business workflows, approval chains, order-fulfillment flows, and any cross-actor process where responsibility (the lane) matters. For interaction timelines use seqdiag; for static block structure use blockdiag.

## How-To

### How to add colors, styling & themes
Theme via diagram `default_*` attributes, per-`lane` `color`, per-activity `color`/`style`, and `class` bundles.
```actdiag
actdiag {
  default_shape = roundedbox;
  default_fontsize = 11;
  default_textcolor = "#1a1a2e";

  class decision [shape = diamond, color = "#fff2cc"];
  class error    [color = "#f4cccc", style = dashed];

  submit -> review -> approve;
  review -> fix;
  fix -> review;

  lane author {
    label = "Author"; color = "#e8f0fe";
    submit [label = "Submit Draft"];
    fix    [label = "Revise", class = "error"];
  }
  lane editor {
    label = "Editor"; color = "#e6f4ea";
    review  [label = "Approved?", class = "decision"];
    approve [label = "Publish", color = "#d9ead3"];
  }
}
```
Colors accept CSS names or `#rrggbb`.

### How to build a two-lane user↔system workflow
```actdiag
actdiag {
  login -> browse -> order -> confirm -> notify;

  lane user {
    label = "User";
    login  [label = "Log In", shape = beginpoint];
    browse [label = "Browse"];
    order  [label = "Place Order"];
  }
  lane system {
    label = "System";
    confirm [label = "Confirm Payment"];
    notify  [label = "Send Receipt", shape = endpoint];
  }
}
```

### How to add a decision branch across lanes
```actdiag
actdiag {
  intake -> triage;
  triage -> resolve;
  triage -> escalate;

  lane frontline {
    label = "Support L1";
    intake [label = "Ticket In", shape = beginpoint];
    triage [label = "Simple?", shape = diamond];
    resolve [label = "Resolve"];
  }
  lane specialist {
    label = "Support L2";
    escalate [label = "Escalate", color = "#fce5cd"];
  }
}
```

### How to switch layout orientation
```actdiag
actdiag {
  orientation = portrait;   // lanes flow top-to-bottom; default landscape is left-to-right
  a -> b -> c;
  lane one { label = "Phase 1"; a; b; }
  lane two { label = "Phase 2"; c; }
}
```

## Do's and Don'ts

### ✅ Do
- Declare the flow edges (`A -> B -> C;`) and let lanes only assign band membership.
- Give every activity a home lane; unassigned nodes still render but land in the last lane implicitly — assign explicitly for clarity.
- Use `shape = diamond` for decisions and `beginpoint`/`endpoint` for terminals.
- Tint lanes with `color` to make ownership obvious.
- Quote multi-word labels — `[label = "Process Order"]`.

### ❌ Don't
- Don't put the same node in two lanes — each activity belongs to exactly one lane.
- Don't expect seqdiag-style lifelines — actdiag models *activity flow*, not message timing.
- Don't invent shapes — stick to the family shape set (`box`, `roundedbox`, `diamond`, `circle`, `note`, `beginpoint`, `endpoint`, …).
- Don't run `blockdiag` on an activity file — use the `actdiag` command.
- Don't rely on manual coordinates — layout is automatic.

## Styling, Theming & Customization
Theming is inline: `default_*` diagram attributes set the baseline, `lane { color = … }` tints each band, and node `color`/`shape`/`style`/`class` style individual activities. A conventional scheme tints each lane a distinct pastel (user = blue, system = green, error path = red) so the reader tracks hand-offs at a glance. `class` factors repeated decision/error looks.

## Advanced Features
- **Swimlanes** are the headline feature — activities grouped by owning actor with automatic cross-lane routing.
- **Branching**: multiple outgoing edges from a `diamond` model decisions.
- **Merge**: multiple edges into one node model joins.
- **`orientation`** flips lane direction (portrait vs landscape).
- **Sphinx**: `.. actdiag::` directive renders inline in docs.

## Common Pitfalls & Troubleshooting
- **Node in the wrong lane**: it is placed in whichever `lane` block declares it; move the declaration.
- **Edges look tangled**: reorder lanes so the dominant flow runs across adjacent bands.
- **Decision not diamond-shaped**: set `shape = diamond` explicitly.
- **PDF fails**: install `"actdiag[pdf]"`.
- **Non-ASCII labels are boxes**: pass `-f /path/Font.ttf`.

## Integration Notes
- **Sphinx**: `sphinxcontrib-actdiag` provides the `.. actdiag::` directive.
- **Kroki**: https://kroki.io renders actdiag server-side — POST the source to `https://kroki.io/actdiag/svg` with no local install.
- **MkDocs / Markdown**: embed via the `mkdocs-kroki-plugin` or a Kroki fenced block.
- **CI**: `.diag` sources diff cleanly; render to SVG in a build step or via Kroki on demand.

## Best For / Avoid For
`activity-diagrams`, `swimlane-workflows`, `business-process`, `approval-flows`, `cross-team-handoffs` — choose actdiag when responsibility per step (the lane) is the point. Avoid for message-timing (use seqdiag), static architecture (blockdiag), or rich BPMN with gateways/events (use mermaid/PlantUML/BPMN tools).

## See Also
- Family siblings: `seqdiag.md` (sequence/timing), `blockdiag.md` (core blocks/flow), `nwdiag.md` (networks), `rackdiag.md` (racks), `packetdiag.md` (packet fields)
- Alternatives: `mermaid.md` (flowchart/sequence in Markdown), `graphviz.md` (DOT graph layout)
- Use cases: `../use-case/diagram-generation.md`, `../use-case/networks-graphs.md`
