# seqdiag — UML sequence diagram generator from text

seqdiag renders UML sequence diagrams from a compact text grammar: you name participants and write `A -> B [label = "…"]` messages, and seqdiag lays out lifelines, activation bars, and time ordering automatically. It is part of the *blockdiag family* and shares its `{ }` block grammar. Output is PNG, SVG, or PDF via a Python CLI.

**Current Version**: seqdiag 3.x (3.0.0+)  **License**: Apache 2.0  **Runtime**: Python 3.7+ CLI (no browser)

## Official Resources & Documentation
- Home / docs: http://blockdiag.com/en/seqdiag/
- Examples: http://blockdiag.com/en/seqdiag/examples.html
- GitHub: https://github.com/blockdiag/seqdiag
- PyPI: https://pypi.org/project/seqdiag/
- Sphinx extension: https://pypi.org/project/sphinxcontrib-seqdiag/

## Installation & Setup
```bash
pip install seqdiag
pip install "seqdiag[pdf]"             # reportlab-backed PDF output
pip install sphinxcontrib-seqdiag      # Sphinx directives
```
CLI rendering (command is `seqdiag`):
```bash
seqdiag flow.diag                      # -> flow.png
seqdiag flow.diag -T svg -o flow.svg   # SVG
seqdiag flow.diag -T pdf -o flow.pdf   # PDF (needs [pdf] extra)
seqdiag -f /path/Font.ttf flow.diag    # embed a TTF for non-ASCII labels
```

## Shared blockdiag-family Grammar
seqdiag wraps its body in `seqdiag { … }`. These constructs are common to the whole family; seqdiag-specific message syntax follows.

**Comments**: `// line` and `# line`.

**Diagram-level attributes**: `default_shape`, `default_node_color`, `default_fontsize`, `default_textcolor`, `node_width`, `node_height`, `span_height`, plus seqdiag-specific `activation` (`none` to hide activation bars), `autonumber` (`True` to auto-number messages), `edge_length` (horizontal spacing between lifelines), and `default_note_color`.

**Participant (node) attributes** — `name [attr = value];`: `label`, `color`, `shape` (`box`, `actor`, etc.), `textcolor`, `fontsize`, `numbered`, `stacked`. Declaring a participant early fixes its left-to-right order.

**Edge (message) attributes** — `A -> B [attr = value];`: `label`, `return` (auto-return caption), `color`, `style` (`dashed`/`dotted`), `note` / `leftnote` / `rightnote` (attach a note to the message), `failed` (dropped message), `diagonal` (slanted, for latency).

**Classes** bundle reusable attributes: `class svc [color = "#cfe2f3"];` then `node [class = "svc"]`.

## Core Syntax / seqdiag Arrows
seqdiag distinguishes four forward operators; prefix-reverse each with `<` to point back. Direction is left↔right along the time axis.

| Arrow | Meaning |
|-------|---------|
| `->`  | synchronous message (solid line, solid arrowhead) |
| `-->` | dashed message — conventionally a **return** or asynchronous reply |
| `=>`  | synchronous **call with auto-generated return** (nested); pair with `return = "…"` |
| `==>` | dashed variant of the auto-return call |
| `<-` / `<--` | same as above but reversed (message flows right→left) |

```seqdiag
seqdiag {
  browser; server; db;

  browser -> server [label = "GET /order"];   // sync request
  server  -> db     [label = "SELECT"];        // sync
  db     --> server [label = "rows"];          // dashed return
  server --> browser [label = "200 OK"];       // dashed return
}
```

**Auto-return with `=>`** — one line draws both the call and its return:
```seqdiag
seqdiag {
  user; app; auth;
  user => app  [label = "login", return = "session"];
  app  => auth [label = "verify", return = "ok"];
}
```

**Chaining** — write successive messages top-to-bottom; time flows down:
```seqdiag
seqdiag {
  a -> b [label = "step 1"];
  b -> c [label = "step 2"];
  c -> a [label = "step 3"];
}
```

**Self / nested messages** (`A -> A`) and explicit activation via nested braces:
```seqdiag
seqdiag {
  client; service;
  client -> service [label = "process"] {
    service -> service [label = "validate"];   // self-message
    service -> service [label = "transform"];
  }
}
```
Nesting messages inside `{ … }` under a call keeps the caller's activation bar open for the enclosed exchanges.

**Auto-numbering** — number every message automatically:
```seqdiag
seqdiag {
  autonumber = True;
  a -> b [label = "first"];   // rendered "1: first"
  b -> c [label = "second"];  // "2: second"
}
```

**Activation control** — bars are on by default; disable globally or per edge:
```seqdiag
seqdiag {
  activation = none;          // hide all activation bars
  a -> b [label = "call"];
  b -> a [label = "ack"];
}
```

**Notes** attach commentary to a message via `note`, `leftnote`, or `rightnote`:
```seqdiag
seqdiag {
  a -> b [label = "request", leftnote = "sent by client"];
  b -> a [label = "reply", rightnote = "cached 60s"];
}
```

**Separators** divide phases:
```seqdiag
seqdiag {
  a -> b [label = "connect"];
  === handshake complete ===
  a -> b [label = "send data"];
}
```

**Failed / lost message** and **diagonal (latency) edges**:
```seqdiag
seqdiag {
  a -> b [label = "timeout", failed];
  a -> c [label = "slow link", diagonal];
}
```

## Diagram / Output Types
seqdiag draws **UML sequence diagrams**: request/response flows, authentication handshakes, API call chains, message-passing between services, and self/nested calls with activation. For activity/swimlane flows use actdiag; for static structure use blockdiag.

## How-To

### How to add colors, styling & themes
Theme with diagram `default_*` attributes, per-participant `color`, per-message `color`/`style`, and `class` bundles.
```seqdiag
seqdiag {
  default_fontsize = 11;
  default_note_color = "#fff2cc";

  class ext [color = "#f4cccc"];

  browser [color = "#d9ead3"];
  gateway [color = "#cfe2f3"];
  payment [class = "ext"];

  browser -> gateway [label = "checkout", color = "#4a86e8"];
  gateway -> payment [label = "charge", color = "#cc0000", style = dashed];
  payment --> gateway [label = "receipt"];
  gateway --> browser [label = "confirmation"];
}
```
Colors accept CSS names or `#rrggbb`.

### How to model a call with an automatic return
```seqdiag
seqdiag {
  client; api; cache;
  client => api   [label = "getUser", return = "user"];
  api    => cache [label = "lookup", return = "hit"];
}
```

### How to auto-number a multi-step protocol
```seqdiag
seqdiag {
  autonumber = True;
  c -> s [label = "SYN"];
  s -> c [label = "SYN-ACK"];
  c -> s [label = "ACK"];
}
```

### How to add notes and phase separators
```seqdiag
seqdiag {
  a -> b [label = "open", rightnote = "TLS 1.3"];
  === session established ===
  a -> b [label = "query"];
  b --> a [label = "result", leftnote = "from replica"];
}
```

## Do's and Don'ts

### ✅ Do
- Quote multi-word labels — `[label = "HTTP Request"]`.
- Declare participants first (`browser; server; db;`) to lock their left-to-right order.
- Use `-->` for returns/replies and `->` for calls — the dashed line reads as a response.
- Use `=>` + `return = "…"` to avoid writing a separate return line.
- Set `autonumber = True` for protocol diagrams where step order matters.

### ❌ Don't
- Don't expect fragments (`alt`/`opt`/`loop` boxes) — seqdiag has no combined fragments; approximate with separators and notes, or use mermaid/PlantUML for those.
- Don't rely on declaration order of *messages* for participant order — participant order comes from first appearance or explicit declaration.
- Don't mix up `=>` (auto-return) with `->` (single message); `=>` draws two lines.
- Don't run `blockdiag` on a sequence file — use the `seqdiag` command.
- Don't nest braces expecting swimlanes; braces only extend activation, not lanes.

## Styling, Theming & Customization
Theming is inline: `default_*` diagram attributes set the baseline, participant `color`/`shape` style the heads, message `color`/`style` style the arrows, and `default_note_color` tints notes. `class` factors shared looks (e.g., an `ext` class for third-party services). `activation = none` yields a cleaner, bar-free look for high-level flows.

## Advanced Features
- **Auto-return** (`=>`, `==>`) collapses a call+return into one statement.
- **Nested activation** via `A -> B { … }` keeps a caller active across sub-calls.
- **`failed`** marks dropped messages; **`diagonal`** slants an edge to depict latency.
- **`edge_length`** widens lifeline spacing; **`span_height`** adjusts vertical gaps.
- **Sphinx**: `.. seqdiag::` directive renders inline in docs.

## Common Pitfalls & Troubleshooting
- **Participants in the wrong order**: declare them explicitly at the top in the order you want.
- **No return line appearing**: use `=>`/`==>` with `return = "…"`, or add an explicit `-->` message.
- **Activation bars cluttering a high-level view**: set `activation = none`.
- **PDF fails**: install `"seqdiag[pdf]"`.
- **Non-ASCII labels are boxes**: pass `-f /path/Font.ttf`.

## Integration Notes
- **Sphinx**: `sphinxcontrib-seqdiag` provides the `.. seqdiag::` directive.
- **Kroki**: https://kroki.io renders seqdiag server-side — POST the source to `https://kroki.io/seqdiag/svg` with no local install.
- **MkDocs / Markdown**: embed via the `mkdocs-kroki-plugin` or a Kroki fenced block.
- **CI**: `.diag` sources diff cleanly; render to SVG in a build step or via Kroki on demand.

## Best For / Avoid For
`sequence-diagrams`, `api-flows`, `auth-handshakes`, `service-interactions`, `protocol-steps` — choose seqdiag for clean request/response timelines from text. Avoid when you need alt/loop/opt fragments, gates, or interactive diagrams (use mermaid sequence or PlantUML instead).

## See Also
- Family siblings: `actdiag.md` (activity/swimlanes), `blockdiag.md` (core blocks/flow), `nwdiag.md` (networks), `rackdiag.md` (racks), `packetdiag.md` (packet fields)
- Alternatives: `mermaid.md` (sequence with alt/loop/opt), `graphviz.md` (DOT graph layout)
- Use cases: `../use-case/diagram-generation.md`, `../use-case/networks-graphs.md`
