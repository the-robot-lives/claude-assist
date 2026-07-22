# yUML — URL-driven UML DSL rendered by the yuml.me web service

yUML is a tiny text DSL for UML diagrams that renders through the hosted
`yuml.me` service: you encode the diagram in the URL path (or POST it) and get
back a PNG/SVG image. It covers class, use-case, activity, state, package,
deployment and (limited) sequence diagrams. There is no local renderer — the
diagram is produced server-side — which makes it ideal for embedding a diagram
as an `<img>` in Markdown, READMEs, blog posts and wikis. [Docs](https://yuml.me/) | [Class samples](https://yuml.me/diagram/scruffy/class/samples)

**Service**: yuml.me (hosted)  **Cost**: free public endpoint  **Output**: PNG or SVG  **Runtime**: none locally — an HTTP GET/POST returns the image.

## Official Resources & Documentation
- **Home / editor**: https://yuml.me/
- **Class diagram syntax + samples**: https://yuml.me/diagram/scruffy/class/samples
- **Use-case samples**: https://yuml.me/diagram/scruffy/usecase/samples
- **Activity samples**: https://yuml.me/diagram/scruffy/activity/samples
- **API notes**: https://yuml.me/diagram/scruffy/class/draw (interactive draw page)

## Installation & Setup
There is nothing to install. You construct a URL and reference it as an image, or
POST the DSL for longer diagrams.

### URL API form
```text
https://yuml.me/diagram/<style>/<type>/<dsl>[.svg|.png]
```
- `<style>` = `scruffy` | `plain` | `nofunky` | `boring`
- `<type>` = `class` | `usecase` | `activity` | `state` | `sequence` | `deployment` | `package`
- `<dsl>` = the URL-encoded diagram text (elements separated by `,`)
- optional trailing `.svg` or `.png` picks the format (PNG is the default)
- a leading `dir:LR` / `dir:TB` / `dir:RL` element sets diagram direction

### Embed as an image
```html
<!-- PNG (default) -->
<img src="https://yuml.me/diagram/scruffy/class/[Customer]->[Order]">

<!-- SVG, plain style, left-to-right -->
<img src="https://yuml.me/diagram/plain/class/dir:LR,[Customer]->[Order].svg">
```
```markdown
![orders](https://yuml.me/diagram/scruffy/class/[Customer]->[Order])
```

### POST for large diagrams
For diagrams too long for a URL, POST the DSL as form field `dsl_text` to
`https://yuml.me/diagram/<style>/<type>/` and the response body is the image.
Newlines in the POST body separate elements (commas also work).

## Core Syntax / API Reference

Elements are separated by commas (URL form) or newlines (POST form). The two
building blocks are **nodes** (`[...]`, `(...)`, `<...>`, `|...|`) and
**relationships** (operators between two nodes).

### Class diagram nodes
```text
[Customer]                                  // a class
[Customer|forename;surname;email]           // class with attributes
[Customer|forename;surname|register();login()]  // attributes | operations
[note: Customers must have an email{bg:cornsilk}]  // free-floating note
```
- Compartments are separated by `|`: `[Name|attributes|operations]`.
- Members within a compartment are separated by `;`.
- `[note: text]` is a note; add `{bg:color}` to colour it.

### Class relationships
```text
[Customer]-[Order]              // plain association
[Customer]->[Order]            // directional association (arrow at Order)
[Customer]<->[Order]           // bidirectional
[Order]<>-[LineItem]           // aggregation (hollow diamond at Order)
[Order]++-[LineItem]           // composition (filled diamond at Order)
[Customer]^-[PreferredCustomer] // inheritance (PreferredCustomer is-a Customer)
[Shape]^-[Circle]              // inheritance: Circle derives from Shape
[Order]-.-[IOrderable]         // dashed association / interface link
[Order]-.->[IOrderable]        // dependency (dashed, arrow)
[Customer]1-0..*[Order]        // cardinality on each end
[Customer]friends-[Customer]   // association with a label
[Customer]placed>orders-[Order] // role/label + arrow
```
Notes on the operators:
- `<>-` = aggregation, empty diamond on the `<>` side.
- `++-` = composition, filled diamond on the `++` side.
- `^-` (also written `^`) = generalization/inheritance; the arrow's plain end is
  the subclass, the `^` end is the superclass.
- `-.-` = dashed line (interface/realization); `-.->` adds a dependency arrow.
- Cardinality/labels are written as text immediately adjacent to a node bracket:
  `[A]1-0..*[B]`, `[A]role-[B]`, `[A]label>[B]`.
- If unsure of an exotic decorator, prefer these documented forms; yuml.me will
  otherwise render the raw text literally.

### Use-case diagram
```text
[Customer]-(Login)                 // actor to use case
[Customer]-(Browse Products)
(Login)<(Reset Password)          // extension/relation between use cases
(Checkout)>(Payment)
[Customer]-(Checkout)
(Checkout)<<include>>(Payment)     // <<include>> stereotype
(Checkout)<<extend>>(Gift Wrap)    // <<extend>> stereotype
[Admin]-(Manage Catalog)
```
- Actors are `[Actor]`; use cases are `(Use Case)`.
- `<<include>>` and `<<extend>>` express the standard use-case relationships.

### Activity diagram
```text
(start)-><a>                       // start node to a decision
<a>[yes]->(Process Order)          // guarded branch out of decision <a>
<a>[no]->(Cancel)
(Process Order)->|b|               // fork/join bar |b|
|b|->(Ship)
|b|->(Invoice)
(Ship)->(end)
(Invoice)->(end)
```
- `(start)` and `(end)` are the initial/final nodes; `(Action)` is an activity.
- `<a>` is a decision/merge node; `[label]` after a node is the guard on a flow.
- `|a|` is a fork/join synchronization bar.
- Flows chain with `->`: `(start)-><a>[label]->(end)`.

### State diagram
```text
[Idle]->[Running]
[Running]->[Paused]
[Paused]->[Running]
[Running]->[Stopped]
[Stopped]->[Idle]
```
Rendered as states connected by transitions; use `<type>/state` in the URL.

### Deployment diagram
```text
[Web Server|nginx]->[App Server|node]
[App Server]->[Database|postgres]
```
Nodes represent artifacts/nodes; associations are communication paths. Use
`<type>/deployment`.

### Package diagram
```text
[Web]->[Services]
[Services]->[Data Access]
[Data Access]->[Model]
```
Use `<type>/package`; boxes are packages and arrows are dependencies.

### Sequence (limited)
yuml.me exposes a `sequence` type, but its grammar is limited compared to
mermaid/plantuml. For real sequence diagrams (activations, loops, alt/opt
fragments), use plantuml or mermaid instead.

## Supported Diagram Types
`class`, `usecase`, `activity`, `state`, `deployment`, `package`, and a limited
`sequence`. The diagram type is chosen by the `<type>` segment of the URL, and
the same node bracket conventions (`[]`, `()`, `<>`, `||`) mean different things
per type as shown above.

## How-To (worked recipes)

### How to add colors / styling to a yUML diagram
Colour is set inline per element with `{bg:<color>}`, and the overall look is set
by the `<style>` URL segment (`scruffy`/`plain`/`nofunky`/`boring`):
```text
[Customer{bg:orange}]
[Order{bg:cornsilk}]
[note: Aggregate root{bg:wheat}]
[Customer{bg:orange}]<>-orders*>[Order{bg:cornsilk}]
```
Rendered plain, LR, as SVG:
```text
https://yuml.me/diagram/plain/class/dir:LR,[Customer{bg:orange}]<>-*>[Order{bg:cornsilk}].svg
```
`{bg:color}` accepts CSS colour names or hex (`{bg:#ffddaa}`). Apply it to
classes, use cases, activities and notes. The `<style>` segment changes stroke
aesthetics: `scruffy` (sketchy), `plain` (crisp), `nofunky` (no hand-drawn
jitter), `boring` (most formal).

### How to draw a class diagram with cardinality and roles
```text
[Customer|id;name;email]1-0..*[Order|id;total]
[Order]++-1..*>[LineItem|qty;price]
[Order]-.->[IPayable]
[note: Orders belong to exactly one customer{bg:cornsilk}]
```
Encode the whole thing as one comma-separated URL, or POST it with newlines.

### How to model a use case with include/extend
```text
[Shopper]-(Search),
[Shopper]-(Checkout),
(Checkout)<<include>>(Validate Cart),
(Checkout)<<extend>>(Apply Coupon),
(Checkout{bg:palegreen})
```

### How to draw an activity flow with a decision and fork
```text
(start)-><d>,
<d>[in stock]->(Reserve Item),
<d>[backorder]->(Notify Customer),
(Reserve Item)->|f|,
|f|->(Charge Card),
|f|->(Send Confirmation),
(Charge Card)->(end),
(Send Confirmation)->(end)
```

### How to embed a diagram in Markdown / a README
```markdown
![domain model](https://yuml.me/diagram/plain/class/[User|email;password]1-*>[Post|title;body])
```
URL-encode spaces (`%20`) and reserved characters if a renderer does not do it
for you; most Markdown engines pass the raw URL through fine for simple diagrams.

## Do's and Don'ts

### ✅ Do
- Pick the diagram `<type>` in the URL to match your bracket usage — `[]` is a
  class/actor, `()` a use case/activity, `<>` a decision, `||` a fork bar.
- Colour with `{bg:...}` inline and set the global look with the `<style>` segment.
- Use `.svg` for crisp scaling in docs; PNG is the default if you omit the extension.
- POST via `dsl_text` for diagrams longer than a comfortable URL length.
- Separate elements with `,` in URLs and newlines in POST bodies.
- Add `dir:LR` (or `TB`/`RL`) as the first element to control flow direction.

### ❌ Don't
- Don't expect rich sequence diagrams — the `sequence` type is minimal; use
  plantuml/mermaid for detailed interaction diagrams.
- Don't forget URL-encoding: unencoded spaces or `#` in the DSL break the request.
- Don't rely on it offline or in air-gapped builds — rendering requires a request
  to yuml.me; cache the returned image if the pipeline must be reproducible.
- Don't mix node bracket kinds against the diagram type (e.g. `()` use cases in a
  `class` diagram) — the server may render them oddly.
- Don't put `{bg:...}` outside the node brackets; it must be inside: `[X{bg:red}]`.
- Don't send sensitive/proprietary model text — it transits a third-party host.

### Style values quick reference
| `<style>` | look |
|-----------|------|
| `scruffy` | hand-drawn, sketchy strokes (default aesthetic) |
| `plain`   | clean, crisp straight lines |
| `nofunky` | like plain but without the hand-drawn jitter |
| `boring`  | most formal/plain rendering |

## Styling, Theming & Customization
- **Per-element background**: `{bg:color}` inside any node or note bracket.
  Accepts CSS names (`orange`, `cornsilk`, `steelblue`, `palegreen`) or hex.
- **Global aesthetic**: the `<style>` URL segment (`scruffy`/`plain`/`nofunky`/`boring`).
- **Direction**: a leading `dir:LR|TB|RL` element.
- **Format**: append `.svg` or `.png` to the URL.
There is no CSS/class system beyond these — yUML is deliberately minimal. For
fine-grained styling (fonts, per-edge colours, gradients) use graphviz/plantuml.

## Advanced Features
- **Direction control** via `dir:LR|TB|RL` reflows the layout.
- **SVG output** (`.svg`) is scalable and text-selectable, good for high-DPI docs.
- **POST endpoint** lifts the URL-length ceiling for big diagrams.
- **Stereotypes**: `<<include>>` / `<<extend>>` in use-case diagrams; `[Class|...]`
  compartments approximate full class specs.

## Common Pitfalls & Troubleshooting
- **Broken image / 400**: almost always URL-encoding — encode spaces (`%20`),
  and avoid a literal `#` in the DSL (it is reserved).
- **`{bg:}` renders as text**: it was placed outside the brackets; put it inside
  the node it colours.
- **Wrong shapes**: the `<type>` segment doesn't match the bracket kinds you used.
- **Diagram too wide/tall**: add `dir:LR` or `dir:TB` as the first element.
- **Non-reproducible builds**: the render is a live third-party request; snapshot
  the returned PNG/SVG into the repo if determinism matters.
- **Long diagram truncated**: switch from URL GET to a POST with `dsl_text`.

## Best For / Avoid For
`readme-diagrams`, `blog-post-uml`, `quick-class-sketches`, `use-case-diagrams`, `teaching`, `no-toolchain-diagrams` — pick yUML when you want a diagram as a single image URL with zero local setup.

Avoid for: `offline/air-gapped builds`, `detailed-sequence-diagrams`,
`large-complex-models`, `pixel-precise-styling`, or `confidential-content` —
prefer plantuml, mermaid, graphviz, or nomnoml (local render) instead.

## See Also
- [`nomnoml.md`](./nomnoml.md) — sibling text-UML DSL that renders **locally** to SVG/canvas
- [`mermaid.md`](./mermaid.md) — broader diagram types incl. full sequence/gantt/state
- [`plantuml.md`](./plantuml.md) — complete UML grammar, sequence & component diagrams
- [`graphviz.md`](./graphviz.md) — DOT language + layout engines for dense graphs
- [`../use-case/diagram-generation.md`](../use-case/diagram-generation.md) — choosing a diagram tool for a task
