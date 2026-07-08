# nomnoml — Text-based UML sketch tool rendered to SVG/canvas

nomnoml turns a compact, indentation-free text DSL into UML class/flow diagrams
with a clean, slightly hand-drawn aesthetic. Diagrams are described with
bracketed nodes (`[Name]`), typed classifiers (`[<abstract> Name]`), association
operators (`->`, `-:>`, `+-`, ...) and `#`-prefixed directives. It renders in the
browser to SVG or `<canvas>`, runs headless in Node, and is embedded in many
Markdown/wiki toolchains. [Docs](https://nomnoml.com) | [Repo](https://github.com/skanaar/nomnoml) | [npm](https://www.npmjs.com/package/nomnoml)

**Current Version**: nomnoml 1.6+ (current major)  **License**: MIT  **Runtime**: pure JS, ~1 dependency (dagre for layout); renders SVG string or draws to canvas.

## Official Resources & Documentation
- **Live editor / docs**: https://nomnoml.com (the editor page is also the syntax reference)
- **GitHub**: https://github.com/skanaar/nomnoml
- **npm**: https://www.npmjs.com/package/nomnoml
- **Syntax reference (README)**: https://github.com/skanaar/nomnoml#syntax
- **Grammar/source of relation operators**: https://github.com/skanaar/nomnoml/blob/master/src/parser.js

## Installation & Setup

### Package manager (npm)
```bash
npm install nomnoml
# peer/transitive layout dependency (dagre) is bundled in the dist build
```

### CDN / browser
```html
<script src="https://unpkg.com/nomnoml/dist/nomnoml.js"></script>
<canvas id="canvas"></canvas>
<script>
  var source = '[A] -> [B]';
  nomnoml.draw(document.getElementById('canvas'), source);
</script>
```

### ESM / CJS import
```javascript
// ESM
import * as nomnoml from 'nomnoml';
const svg = nomnoml.renderSvg('[Hello] -> [World]');

// CommonJS
const nomnoml = require('nomnoml');
```

## Core Syntax / API Reference

A nomnoml source is a list of lines. Each line is either a **directive**
(starts with `#`), an **association** (two node literals joined by an operator),
or a bare **node declaration**. Whitespace between tokens is not significant, and
nodes referenced by an association are auto-created.

### Nodes
```text
[Plain Node]
[Multi word name is fine]
[Node with \[escaped brackets\] inside]
```
- Wrap names in `[` ... `]`. Escape a literal bracket with a backslash: `\[` `\]`.
- A pipe `|` starts a new **compartment**. A newline inside a compartment is a
  literal line break; a semicolon `;` also breaks a line within a compartment.

### Multi-compartment nodes (classes)
```text
[Account|
  id: int;
  balance: Money
|
  deposit(amount)
  withdraw(amount)
]
```
- First compartment = name (+ optional `<type>` prefix). Following `|`-delimited
  compartments are fields, then methods, etc. You may have any number of them.
- Inside a compartment, separate members with `;` or literal newlines.

### Classifier types (the `<type>` prefix)
Put a type in angle brackets as the first token of the name compartment to change
the shape/semantics of the node:
```text
[<abstract> Shape]
[<instance> shape: Shape]
[<reference> ExternalService]
[<note> This is a floating note]
[<state> Idle]
[<choice> Auth ok?]
[<input> User input]
[<sender> Producer]
[<receiver> Consumer]
[<transceiver> Broker]
[<start> ()]
[<end> ()]
[<actor> Customer]
[<usecase> Place Order]
[<label> free-floating text]
[<hidden> anchor]
[<table> Users| id | name |]
[<frame> Subsystem]
[<package> com.acme.web]
[<database> UserStore]
[<pipe> EventBus]
[<lollipop> IService]
```
Full built-in classifier set: `abstract`, `instance`, `reference`, `note`,
`state`, `choice`, `input`, `sender`, `receiver`, `transceiver`, `start`, `end`,
`actor`, `usecase`, `label`, `hidden`, `table`, `frame`, `package`, `database`,
`pipe`, `lollipop`. (`hidden` renders nothing but still participates in layout —
useful as an invisible routing anchor.)

### Association / arrow operators
An association is `[A] <op> [B]`, optionally with an edge label:
`[A] label -> [B]`. Operators are built from a **line** (`-` solid, `--` dashed)
plus **end decorations**. The common documented set:

```text
[A] - [B]        // plain association (solid line, no arrowhead)
[A] -> [B]       // directed association (arrow at B)
[A] <-> [B]      // bidirectional association
[A] --> [B]      // dependency (dashed, arrow at B)
[A] <--> [B]     // bidirectional dependency (dashed)
[A] -:> [B]      // generalization / inheritance (hollow triangle at B)
[A] <:- [B]      // generalization pointing at A
[A] --:> [B]     // implementation / realization (dashed, hollow triangle at B)
[A] <:-- [B]     // dashed realization pointing at A
[A] +- [B]       // composition (filled diamond at A)
[A] +-> [B]      // composition with arrow at B
[A] o- [B]       // aggregation (hollow diamond at A)
[A] o-> [B]      // aggregation with arrow at B
[A] ->o [B]      // arrow at A end, hollow circle (socket) at B
```
Mental model for building operators: read left-to-right, `<`/`>` = open arrow,
`:>`/`<:` = closed (inheritance) triangle, `+` = filled diamond (composition),
`o` = hollow diamond/circle (aggregation/socket); `-` is a solid line and `--`
is dashed. Combine a left decoration + line + right decoration. If a decorator
combination you need is exotic, prefer one of the documented forms above rather
than guessing — nomnoml silently treats an unrecognized operator as plain text.

### Edge labels
```text
[Order] 1 -> * [LineItem]      // multiplicity as labels on each end
[Customer] places -> [Order]   // single mid-edge label
```
The token(s) between a node and the operator become the near-end label; tokens
after the operator become the far-end label.

### Directives (`#`-prefixed)
One per line, at column 0. Layout, spacing and global style:
```text
#direction: down            // down | right  (top-to-bottom vs left-to-right)
#arrowSize: 1               // relative arrowhead size (float, default 1)
#bendSize: 0.3              // edge corner rounding (0..1)
#gutter: 5                  // space reserved around edge labels
#edgeMargin: 0              // gap between an edge and the node it touches
#gravity: 1                 // pull toward compact layout (float)
#edges: hard               // hard | rounded  (edge corner style)
#padding: 8                 // inner padding inside each node (px)
#spacing: 40                // space between nodes (px)
#font: Calibri              // font family
#fontSize: 12               // base font size (px)
#leading: 1.25              // line height multiplier
#lineWidth: 3               // stroke width for node/edge outlines
#zoom: 1                    // overall scale factor
#title: Diagram Title       // document title (used by some exporters)
#acyclicer: greedy          // greedy = break layout cycles for dagre
#ranker: network-simplex    // network-simplex | tight-tree | longest-path
```
Colour/global-style directives (see Styling section for how they compose):
```text
#background: transparent     // page background
#fill: #fdf6e3; #eee8d5      // node fill; multiple values = alternating shades
#stroke: #33322E             // default outline / text colour
#fillArrows: false           // true = solid filled arrowheads
```
Valid-value notes: `#direction` accepts only `down` or `right`; `#edges` only
`hard` or `rounded`; `#ranker` only the three dagre rankers above; `#fillArrows`,
booleans are `true`/`false`. Numeric directives take a plain number (no `px`).

### Custom style directives (`#.name:`)
Define a reusable named style, then apply it as a classifier `<name>`:
```text
#.box: fill=#8f8 dashed
#.highlight: fill=#lightyellow bold
#.ghost: fill=#eee stroke=#aaa empty

[<box> Reusable Thing]
[<highlight> Important]
[<ghost> Placeholder]
```
Style property keys usable after `#.name:`:
- `fill=<color>` — background fill
- `stroke=<color>` — outline colour
- `title=bold` / `title=underline` / `title=italic` — title-text style (combine, space-separated)
- `body=bold|underline|italic` — non-title compartment text style
- `bold` / `underline` / `italic` — shorthand applying to the whole node
- `dashed` — dashed outline
- `empty` — hide the classifier/title decoration
- `visual=<shape>` — override the rendered shape (see list below)

`visual=` shape values: `actor`, `class`, `database`, `choice`, `circle`,
`ellipse`, `end`, `frame`, `hidden`, `input`, `lollipop`, `none`, `note`,
`package`, `pipe`, `receiver`, `rhomb`, `roundrect`, `sender`, `start`,
`table`, `transceiver`.

### JavaScript API
```javascript
// Render to an SVG string (headless-friendly; pass a document in Node via jsdom)
const svg = nomnoml.renderSvg('[A] -> [B]');
const svg2 = nomnoml.renderSvg(source, customDocument);

// Draw onto an existing <canvas> element, optional scale factor
nomnoml.draw(canvasElement, source, 1.0);

// Compile a source that uses #import directives (resolves included files)
const model = nomnoml.compileFile('diagram.nomnoml');
```
Parse/compile errors throw an object carrying a **`.line`** number (1-based) and
a message, so an authoring pipeline can point at the offending source line:
```javascript
try {
  nomnoml.renderSvg(source);
} catch (e) {
  console.error(`nomnoml error on line ${e.line}: ${e.message}`);
}
```

## Supported Diagram Kinds
nomnoml is not multi-grammar like PlantUML; every diagram uses the same node +
association surface, but the classifier set lets you express:
- **Class diagrams** — multi-compartment `[Name|fields|methods]` with
  generalization/composition/aggregation edges.
- **Object/instance diagrams** — `[<instance> obj: Type]`.
- **Simple flowcharts / activity** — `[<start>]`, `[<choice>]`, `[<end>]`, arrows.
- **State diagrams** — `[<state> Name]` nodes with directed edges.
- **Use-case sketches** — `[<actor> ...]` and `[<usecase> ...]`.
- **Component/deployment sketches** — `[<package>]`, `[<frame>]`, `[<database>]`,
  `[<pipe>]`, `[<lollipop>]`, `[<sender>/<receiver>/<transceiver>]`.
There is **no** sequence-diagram grammar; use mermaid or plantuml for those.

## How-To (worked recipes)

### How to add colors / styling / themes
Combine global `#fill`/`#stroke`/`#background` directives with per-node custom
styles for accent colours:
```text
#background: #ffffff
#fill: #fdf6e3; #eee8d5
#stroke: #33322e
#lineWidth: 2
#.ok: fill=#c8e6c9 title=bold
#.warn: fill=#ffe0b2 dashed
#.err: fill=#ffcdd2 title=bold stroke=#b71c1c

[<start> Request] -> [<ok> Validate]
[Validate] -> [<choice> Valid?]
[Valid?] yes -> [<ok> Process]
[Valid?] no -> [<err> Reject]
[Process] --> [<warn> Retry Queue]
```
`#fill` with two `;`-separated colours produces an alternating fill; `#.name`
styles override per node; `title=bold`/`stroke=` tune individual accents.

### How to model a class hierarchy with interfaces
```text
#direction: down
[<abstract> AbstractRepository|
  #connection: Conn
|
  +find(id)
  +save(entity)
]
[SqlRepository] --:> [IRepository]     // dashed realization
[SqlRepository] -:> [AbstractRepository] // solid inheritance
[<lollipop> IRepository] - [SqlRepository]
```

### How to build a flowchart with a decision branch
```text
#direction: right
[<start> Start] -> [Load Config]
[Load Config] -> [<choice> File found?]
[File found?] yes -> [Parse]
[File found?] no -> [Use Defaults]
[Parse] -> [<end> Done]
[Use Defaults] -> [<end> Done]
```

### How to lay out composition and aggregation
```text
[Car] +-> [Engine]        // composition: Engine lifecycle owned by Car
[Car] +-> [Wheel]
[Team] o-> [Player]       // aggregation: Players exist independently
[Order] 1 +-> * [LineItem]
```

### How to render to SVG in Node and save a file
```javascript
const fs = require('fs');
const { JSDOM } = require('jsdom');
const nomnoml = require('nomnoml');

const dom = new JSDOM('<!DOCTYPE html><body></body>');
const svg = nomnoml.renderSvg('[Node A] -> [Node B]', dom.window.document);
fs.writeFileSync('diagram.svg', svg);
```
`renderSvg` needs a DOM `document`; supply one via `jsdom` when running headless.

## Do's and Don'ts

### ✅ Do
- Declare layout up front: `#direction: right` / `#spacing` / `#padding` before nodes — global directives affect the whole diagram regardless of position, but keeping them at the top keeps sources readable.
- Reuse `#.name:` custom styles instead of repeating inline colours; apply with `[<name> ...]`.
- Escape literal brackets in labels with `\[` and `\]`.
- Use `;` inside compartments to pack multiple members on fewer lines: `[C| a; b; c ]`.
- Use `[<hidden> x]` anchors to nudge layout without drawing an extra visible box.
- Prefer the documented association operators (`->`, `-:>`, `+-`, `o-`, `-->`) — they are the ones the parser recognizes.

### ❌ Don't
- Don't expect sequence diagrams — nomnoml has no sequence/timeline grammar.
- Don't put a space between `#` and a directive name (`# fill:` is not a directive; `#fill:` is). A `#` line that isn't a known directive is treated as a comment-ish no-op and silently ignored.
- Don't append units to numeric directives (`#spacing: 40px` is wrong; use `40`).
- Don't invent operator glyphs; an unrecognized operator degrades to plain text between the nodes rather than erroring visibly.
- Don't rely on indentation for structure — nomnoml is not whitespace-sensitive; structure comes from brackets and operators.
- Don't forget nodes are auto-created by associations — a typo in a node name silently spawns a second node.

## Styling, Theming & Customization
Three layers compose, most-global to most-local:
1. **Directives** (`#fill`, `#stroke`, `#background`, `#lineWidth`, `#font`,
   `#fontSize`, `#fillArrows`) set document-wide defaults.
2. **Custom styles** (`#.name: ...`) define named palettes/shape overrides.
3. **Per-node classifier** (`[<name> ...]`) applies a custom style or built-in type.

A dark-ish theme example:
```text
#background: #1e1e1e
#fill: #2d2d30; #252526
#stroke: #d4d4d4
#font: Menlo
#fontSize: 12
#lineWidth: 1
#fillArrows: true
#.accent: fill=#264f78 title=bold stroke=#569cd6

[<accent> App] -> [Service]
[Service] -> [<database> DB]
```
`#zoom` scales the whole output; `#gravity`, `#spacing`, `#gutter`, `#edgeMargin`,
`#bendSize`, `#acyclicer` and `#ranker` tune the dagre layout when edges cross or
the graph is too tall/wide.

## Advanced Features
- **`#import: other.nomnoml`** includes another source file (resolved by
  `compileFile`) for composing large diagrams from parts.
- **Canvas vs SVG**: `draw()` targets `<canvas>` (good for embedding in a
  bitmap-export pipeline); `renderSvg()` yields scalable vector output.
- **Click/positioning metadata**: the compiled model exposes node positions and
  bounding boxes, enabling overlay/interaction layers.
- **VS Code + web editors**: the live editor at nomnoml.com round-trips source ↔
  rendering and is the fastest way to validate an operator or classifier.

## Common Pitfalls & Troubleshooting
- **Blank / partial render**: usually an unclosed `[` or unbalanced compartment
  `|`. Check the thrown error's `.line`.
- **Two boxes where you meant one**: a misspelled node name in an association
  auto-creates a new node. Names must match exactly (case-sensitive).
- **Directive "ignored"**: leading space after `#`, wrong value domain (e.g.
  `#direction: up`), or `px` suffix on a number.
- **Colours not applying**: `#.name:` style must be referenced as `[<name> ...]`;
  the `<name>` must match the style key exactly.
- **Overlapping/ugly layout**: raise `#spacing`, set `#direction`, or switch
  `#ranker` to `tight-tree` / `longest-path`; add `#acyclicer: greedy` if the
  graph has cycles that confuse dagre.
- **Node needs literal `|` or `[`**: escape brackets with `\`; a literal pipe in
  a label is awkward — prefer a different separator or a `<label>` node.

## Best For / Avoid For
`quick-uml-sketches`, `class-diagrams`, `conceptual-flowcharts`, `docs-embedded-diagrams`, `hand-drawn-aesthetic`, `version-controlled-diagram-source` — choose nomnoml when you want terse text UML with minimal ceremony.

Avoid for: `sequence-diagrams`, `gantt/timeline`, `precise-swimlane-layouts`,
`large-auto-laid-out-graphs`, or pixel-exact styling — reach for mermaid,
plantuml, or graphviz instead.

## See Also
- [`yuml.md`](./yuml.md) — sibling text-UML DSL (URL-API service, class/usecase/activity)
- [`mermaid.md`](./mermaid.md) — broader diagram-type coverage incl. sequence/gantt
- [`plantuml.md`](./plantuml.md) — full UML grammar, sequence & component diagrams
- [`graphviz.md`](./graphviz.md) — DOT language + layout engines for dense graphs
- [`../use-case/diagram-generation.md`](../use-case/diagram-generation.md) — choosing a diagram tool for a task
