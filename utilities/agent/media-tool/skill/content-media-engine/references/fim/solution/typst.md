# Typst — Modern markup-based typesetting

Typst is a markup-based typesetting system positioned as a faster, friendlier LaTeX alternative. It combines readable Markdown-like markup with a full scripting language (set/show rules, functions, closures) and compiles to PDF/PNG/SVG in milliseconds with incremental recompilation. Designed for scientific papers, reports, theses, and slides.

**Current Version**: Typst 0.12.x (pre-1.0; syntax mostly stable, minor breaking changes possible)  **License**: Apache-2.0  **Runtime**: single Rust binary `typst`; web app at typst.app; packages via Typst Universe

## Official Resources & Documentation
- **Website / web app**: https://typst.app/
- **Documentation**: https://typst.app/docs/
- **Reference (functions)**: https://typst.app/docs/reference/
- **Tutorial**: https://typst.app/docs/tutorial/
- **Package registry (Typst Universe)**: https://typst.app/universe/
- **GitHub**: https://github.com/typst/typst

## Installation & Setup
```bash
# Prebuilt binary
brew install typst                     # macOS
cargo install typst-cli                # via Rust
# Linux: download from GitHub releases and place on PATH

# Web editor (no install): https://typst.app
```
```bash
typst compile document.typ             # -> document.pdf
typst compile document.typ out.png     # PNG
typst compile --format svg doc.typ out.svg
typst watch document.typ               # live incremental recompile
typst compile --font-path ./fonts doc.typ
```

## Core Syntax Reference
Typst has three modes: **markup** (default), **math** (inside `$...$`), and **code** (inside `#{...}` or after `#`).

### Markup basics
```typst
= Heading level 1
== Heading level 2
=== Heading level 3

Normal paragraph. *bold* _italic_ `raw/monospace`.
A line break \
Escape a symbol with a backslash: \*not bold\*.

- bullet list
  - nested
+ numbered list
+ second

/ Term: definition list entry

#link("https://typst.app")[Typst site]
#image("diagram.png", width: 80%)
```
Blank lines separate paragraphs. Headings use `=` (count = level), the reverse of nothing-else-needed simplicity.

### Set rules (configure defaults)
```typst
#set document(title: "Research Paper", author: "Author Name")
#set page(paper: "a4", margin: 2cm, numbering: "1")
#set text(font: "New Computer Modern", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
```
`#set f(args)` sets the default arguments for every subsequent call to element function `f`. This is Typst's primary configuration mechanism.

### Show rules (transform elements)
```typst
// Style every heading
#show heading: it => text(fill: rgb("#1e6fba"), weight: "bold", it.body)

// Replace text patterns
#show "TODO": strong[⚠ TODO]

// Template pattern: wrap the whole document
#show: doc => columns(2, doc)
```
`#show selector: transform` rewrites matching elements — the mechanism behind templates and theming.

### Math mode
```typst
Inline math: $x^2 + y^2 = z^2$.

Block (display) math:
$ x = (-b plus.minus sqrt(b^2 - 4 a c)) / (2 a) $

Matrix and cases:
$ mat(1, 2; 3, 4) $
$ f(x) = cases(x "if" x >= 0, -x "otherwise") $

Sums / integrals:
$ sum_(i=1)^n i = (n(n+1)) / 2 $
$ integral_0^oo e^(-x^2) dif x = sqrt(pi) / 2 $
```
Math uses **words** for symbols (`plus.minus`, `sqrt`, `integral`, `sum`, `oo`), multi-letter identifiers need quotes or spacing, and `$ ... $` with surrounding spaces means display mode.

### Functions & code
```typst
#let accent = rgb("#e8590c")
#let note(body) = block(fill: accent.lighten(80%), inset: 8pt, radius: 4pt, body)

#note[This is a reusable callout defined as a function.]

#let squared(x) = x * x
The result is #squared(6).

// Loops / conditionals in code mode
#for i in range(1, 4) [ Item #i \ ]
#if 3 > 2 [true branch]
```
`#let name = value` binds variables/functions. Content blocks `[...]` are first-class values you can pass to functions.

### Figures, tables, references
```typst
#figure(
  image("chart.png", width: 70%),
  caption: [System architecture.],
) <fig-arch>

#figure(
  table(
    columns: 3,
    align: (left, center, right),
    table.header[Name][Count][Price],
    [Widget], [5], [9.99],
    [Gadget], [3], [19.99],
  ),
  caption: [Results.],
) <tab-results>

As shown in @fig-arch and @tab-results.
```
`<label>` attaches a label; `@label` references it. Figures auto-number when `#set figure(numbering: "1")`.

### Raw / code blocks with highlighting
Fenced blocks (triple-backtick with a language tag) are highlighted automatically; inline raw uses the `raw` function:
```typst
#raw("def greet(name):\n    return name", lang: "python", block: true)

Inline raw with language: #raw("const x = 1", lang: "js")
```
Typst bundles a syntax highlighter, so a normal ```` ```python ```` fenced block in markup mode is colorized without extra setup.

## How-To (worked recipes)

### How to add colors & styling
Use `rgb()`/`luma()`/named colors with `text(fill: ...)`, `block(fill: ...)`, and show rules:
```typst
#let brand = rgb("#1e6fba")

// Inline colored text
Some #text(fill: brand)[branded] and #text(fill: red)[error] words.

// Colored, filled callout box
#block(fill: brand.lighten(85%), stroke: (left: 3pt + brand),
       inset: 10pt, radius: 4pt)[
  *Note:* this box is themed with the brand color.
]

// Color every heading via a show rule
#show heading: set text(fill: brand)
```
`color.lighten()/darken()/transparentize()` derive palette variants — the idiomatic "add colors" path. Colors accept hex (`rgb("#RRGGBB")`), component `rgb(30, 111, 186)`, `cmyk(...)`, and `luma(n)` grayscale.

### How to build a reusable template
```typst
#let report(title: "", author: "", body) = {
  set document(title: title, author: author)
  set page(numbering: "1")
  set text(font: "New Computer Modern", size: 11pt)
  align(center)[#text(18pt, weight: "bold")[#title] \ #author]
  body
}

#show: report.with(title: "Quarterly Report", author: "Data Team")

= Introduction
Content flows through the template.
```
`#show: fn` pipes the whole document through `fn` — the standard template idiom.

### How to reference sections, figures, and equations
```typst
#set heading(numbering: "1.1")
= Introduction <intro>

$ E = m c^2 $ <emc2>

See @intro and equation @emc2.
```

### How to use community packages
```typst
#import "@preview/cetz:0.3.0": canvas, draw   // drawing/plots
#import "@preview/tablex:0.0.8": tablex        // advanced tables

#canvas({
  import draw: *
  circle((0, 0), radius: 1)
  line((0,0), (2,0))
})
```
Packages are pulled from Typst Universe by `@preview/name:version`. `cetz` (TikZ-like drawing), `fletcher` (diagrams/graphs), `polylux` (slides), `physica`, `unify` are common.

## Do's and Don'ts

### ✅ Do
- Configure defaults with **`#set`** at the top rather than styling each element inline.
- Build **templates as functions** and apply with `#show: template.with(...)`.
- Use **`typst watch`** for instant feedback (incremental compile is the headline feature).
- Prefer **labels + `@ref`** over manual numbering.
- Pin **package versions** (`@preview/cetz:0.3.0`) for reproducible builds.

### ❌ Don't
- Don't expect LaTeX macros/packages to work — Typst is a separate ecosystem; find the Typst-Universe equivalent.
- Don't forget the **spaces around display math** — `$x$` is inline, `$ x $` is display; the spacing is significant.
- Don't use LaTeX-style backslash symbols in math — Typst uses words (`alpha`, `sqrt`, `->`), not `\alpha`.
- Don't rely on 0.x syntax being frozen — pin the compiler version for long-lived docs (pre-1.0).
- Don't mix modes carelessly — `#` enters code/expression mode; content needs `[...]` blocks.

## Styling, Theming & Customization
- **Page/text/par**: `#set page(...)`, `#set text(...)`, `#set par(...)` for margins, fonts, justification, numbering.
- **Show rules**: retheme any element type (`#show heading:`, `#show raw:`, `#show link:`).
- **Colors**: `rgb`/`cmyk`/`luma` + `.lighten()/.darken()`; `fill`/`stroke` on `block`, `rect`, `text`.
- **Fonts**: `#set text(font: "Font Name")`; supply custom fonts via `--font-path`.
- **Templates**: distribute as packages; many journal/thesis templates live on Typst Universe.

## Advanced Features
- **Full scripting**: variables, functions, closures, loops, conditionals, arrays, dictionaries — generate content programmatically.
- **`cetz`** — programmatic vector drawing and plots (TikZ analog); **`fletcher`** — node/edge diagrams and adjacency graphs.
- **State & counters**: `counter()`, `state()` for custom numbering and cross-document values.
- **Bibliography**: `#bibliography("refs.bib")` with `@key` citations; supports BibTeX and Hayagriva YAML.
- **Slides**: `polylux` / built-in for presentation output.
- **Data**: `json()`, `csv()`, `toml()`, `yaml()` load external data into the document.

## Common Pitfalls & Troubleshooting
- **Math symbol not found** → use the word form (`plus.minus`, not `\pm`); check the symbol reference.
- **Inline math where you wanted display** → add spaces inside `$ ... $`.
- **Package won't import** → wrong `@preview/name:version` or offline; run once online to cache.
- **Font missing** → install the font or pass `--font-path`; Typst won't silently substitute silently in the same way.
- **Breaking change after upgrade** → pin the compiler; 0.x releases occasionally change syntax.
- **`#` in prose renders as code** → escape it (`\#`) or it starts an expression.

## Integration Notes
- **CI**: single static binary — trivial to run in pipelines (no multi-GB TeX install).
- **Editors**: official LSP (`typst-lsp`/`tinymist`) gives completion and preview in VS Code/Neovim.
- **Pandoc**: experimental Typst writer exists for Markdown→Typst.
- **Not LaTeX-compatible**: cannot consume `.tex`/`.sty`; migrate content, not templates.

## Best For / Avoid For
`academic-papers`, `reports`, `theses`, `math`, `slides`, `fast-iteration` — choose Typst for LaTeX-quality output with far faster compiles and a friendlier language.
Avoid for: journals that mandate a specific LaTeX class (use latex.md), workflows depending on mature LaTeX packages with no Typst port, or web content (use markdown.md).

## See Also
- `latex.md` — the incumbent Typst competes with; richer package ecosystem
- `markdown.md` — lighter markup for web content
- `pandoc.md` — format conversion (experimental Typst support)
- `../use-case/document-processing.md`, `../use-case/document-processing.md`
