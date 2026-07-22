# AsciiDoc — Semantic technical-documentation markup

AsciiDoc is a plain-text markup language for technical documentation, articles, and books, processed primarily by **Asciidoctor** (Ruby, with JS/Java ports). It offers richer built-in semantics than Markdown — native tables, admonitions, cross-references, includes, attribute lists, callouts, and source highlighting — while staying readable in source form. Output targets include HTML5, PDF, DocBook, EPUB, and man pages.

**Current Version**: Asciidoctor 2.0.x · AsciiDoc Language spec (in progress at asciidoc.org)  **License**: MIT (Asciidoctor)  **Runtime**: Ruby gem `asciidoctor`; `asciidoctor.js` for browser/Node; `asciidoctorj` for JVM

## Official Resources & Documentation
- **AsciiDoc language**: https://asciidoc.org/
- **Asciidoctor docs**: https://docs.asciidoctor.org/
- **Syntax quick reference**: https://docs.asciidoctor.org/asciidoc/latest/syntax-quick-reference/
- **Asciidoctor repo**: https://github.com/asciidoctor/asciidoctor
- **asciidoctor-pdf**: https://github.com/asciidoctor/asciidoctor-pdf
- **asciidoctor.js**: https://github.com/asciidoctor/asciidoctor.js
- **Live preview (browser)**: https://asciidoclive.com/

## Installation & Setup
### Ruby (canonical)
```bash
gem install asciidoctor            # core HTML5 converter
gem install asciidoctor-pdf        # PDF backend
gem install rouge coderay          # source highlighters
```
### Node.js
```bash
npm install asciidoctor            # asciidoctor.js
```
```javascript
const asciidoctor = require('asciidoctor')();
const html = asciidoctor.convert('= Title\n\nHello *world*.');
```
### Conversion commands
```bash
asciidoctor doc.adoc                       # -> doc.html
asciidoctor -b docbook5 doc.adoc           # -> DocBook XML
asciidoctor-pdf doc.adoc                   # -> doc.pdf
asciidoctor -a toc -a numbered doc.adoc    # set attributes on the CLI
```

## Core Syntax Reference

### Document header & attributes
```asciidoc
= Document Title
Author Name <author@example.com>
v2.1, 2024-06-01
:toc: left
:toclevels: 3
:numbered:
:icons: font
:source-highlighter: rouge
:imagesdir: ./images
```
The header is the first block; a blank line ends it. `:name: value` sets a document attribute. Reference attributes inline with `{name}`.

### Section levels
```asciidoc
= Level 0 (document title, only one)
== Level 1
=== Level 2
==== Level 3
===== Level 4
```
Section level = number of `=`. Only one Level 0 per document (book/article title).

### Inline formatting
```asciidoc
*bold*  _italic_  `monospace`
#highlight#  ^superscript^  ~subscript~
*_bold italic_*   `*monospace bold*`
[.underline]#underlined#   [.line-through]#struck#
[red]#red text#            (needs a role->CSS mapping)
```
Constrained (word-boundary) vs unconstrained (`**bold**` mid-word) — double the marker to force formatting inside a word.

### Lists
```asciidoc
* unordered
** nested
*** deeper

. ordered
.. nested ordered

Term:: definition
Another term:: its definition

- [ ] unchecked task
- [x] checked task
```

### Links, images, cross-references
```asciidoc
https://asciidoc.org[AsciiDoc site]
link:downloads/file.zip[Download]
mailto:me@example.com[Email me]

image::diagram.png[Architecture,600,400]     // block image
image:icon.png[inline icon,24]                // inline image

<<section-id>>                                 // xref by ID
<<section-id,custom link text>>
xref:other.adoc#anchor[See other doc]
```
Assign an explicit ID with `[[section-id]]` or `[#section-id]` before a block/heading.

### Admonitions
```asciidoc
NOTE: Single-line admonition.

[WARNING]
====
Multi-line admonition block.
With multiple paragraphs.
====
```
Types: `NOTE`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`. With `:icons: font`, they render with Font Awesome icons.

### Source code with highlighting & callouts
```asciidoc
[source,python]
----
def greet(name):       # <1>
    return f"Hi {name}" # <2>
----
<1> Function definition
<2> Formatted return
```
The `<1>` callouts become numbered annotations. `:source-highlighter:` must be set (`rouge`, `highlight.js`, `pygments`, `coderay`).

### Tables
```asciidoc
[cols="1,2,>1",options="header"]
|===
| ID | Description | Price

| 1  | Widget      | 9.99
| 2  | Gadget      | 19.99
|===
```
`cols` sets column count/width/alignment (`<` left, `^` center, `>` right; `a` = AsciiDoc content, `h` = header cell). `options="header,footer,autowidth"`.

### Includes (modular docs)
```asciidoc
include::chapters/intro.adoc[]
include::code/example.py[lines=10..25]
include::shared/legal.adoc[leveloffset=+1]
```
`include::` composes documents from parts — the defining feature for book-scale authoring. `leveloffset` re-ranks headings of the included file.

### Blocks (delimited)
```asciidoc
====   example block
****   sidebar
....   literal (verbatim, no substitutions)
----   listing / source
////   comment (not rendered)
++++   passthrough (raw output, e.g. embedded HTML)
--     open block (generic)
```

## Output Backends
- **HTML5** (default) — single-file or with assets.
- **PDF** — `asciidoctor-pdf` (theme-able via YAML).
- **DocBook 5** — bridge to the full DocBook toolchain (see docbook.md).
- **EPUB3** — `asciidoctor-epub3`.
- **Man page** — `-b manpage`.
- **reveal.js slides** — `asciidoctor-revealjs`.

## How-To (worked recipes)

### How to add colors / styling (roles → CSS)
AsciiDoc styling is done with **roles** — semantic class names you map to CSS. This is the "how to add colors" recipe:
```asciidoc
:stylesheet: custom.css

[.highlight]#important phrase#
[.text-danger]#error state#

[cols="1,1",role="striped compact"]
|===
| A | B
|===
```
```css
/* custom.css loaded alongside the HTML output */
.highlight { background: #fff3b0; }
.text-danger { color: #c0392b; font-weight: 600; }
```
Register a custom stylesheet with `:stylesheet:` (and `:linkcss:` to link rather than embed). Roles keep color decisions out of the prose and in CSS — the idiomatic AsciiDoc pattern.

### How to build a reusable admonition with an icon
```asciidoc
:icons: font

[TIP]
====
Set `:icons: font` in the header so admonitions render with Font Awesome
glyphs instead of text labels.
====
```

### How to cross-reference figures and sections
```asciidoc
[#fig-arch]
.System architecture
image::arch.png[Architecture]

As shown in <<fig-arch>>, the components are decoupled.
```
The block title (`.System architecture`) plus an ID makes a numbered, linkable figure.

### How to conditionally include content per output
```asciidoc
ifdef::backend-pdf[]
This paragraph appears only in the PDF build.
endif::[]

ifeval::["{edition}" == "pro"]
Pro-only content.
endif::[]
```
Combine with `-a edition=pro` on the CLI for single-source, multi-variant docs.

## Do's and Don'ts

### ✅ Do
- Use **document attributes** (`:name:`) for values reused across the doc (versions, paths, product names) and reference them as `{name}`.
- Use **`include::`** to break large docs into files and compose a master document.
- Assign **explicit IDs** (`[#id]`) to any block you'll cross-reference — auto-generated IDs are brittle.
- Set **`:source-highlighter:`** for code; without it, code blocks are plain monospace.
- Prefer **roles + CSS** over passthrough HTML for styling.

### ❌ Don't
- Don't confuse AsciiDoc with Markdown — `*text*` is **bold** in AsciiDoc (Markdown italic), and `_text_` is italic. Mixing conventions produces wrong output.
- Don't forget the blank line after the document header — without it the author line merges into the title block.
- Don't rely on `++++` passthrough HTML for PDF/DocBook targets — raw HTML only survives the HTML backend.
- Don't hand-number sections — set `:numbered:` and let Asciidoctor number them.
- Don't nest list markers inconsistently — `**` must sit under `*`, not `-`.

## Styling, Theming & Templates
- **HTML**: default `asciidoctor.css`; override with `:stylesheet:`/`:stylesdir:`, or `:linkcss:` to link external CSS. Roles (`[.role]#text#`, `role=` on blocks) become CSS classes.
- **PDF**: `asciidoctor-pdf` uses a **theme YAML** (`-a pdf-theme=my-theme.yml -a pdf-themesdir=themes`) controlling fonts, colors, margins, running headers/footers.
- **Custom converters**: subclass the HTML5 converter (Ruby) to override how any node renders — full templating control.
- **Icons**: `:icons: font` (Font Awesome) or `:icons:` (image icons).

## Advanced Features
- **Extensions API** (Ruby): block macros, inline macros, tree processors, postprocessors — e.g. `asciidoctor-diagram` renders embedded PlantUML/Mermaid/Graphviz blocks to images at build time.
- **`asciidoctor-diagram`**: `[plantuml]`, `[mermaid]`, `[graphviz]` blocks compile to SVG/PNG inline.
- **Bibliography & footnotes**: `footnote:[text]`, `[bibliography]` sections with `[[[ref]]]` entries.
- **Counters & attributes**: `{counter:seq}` for auto-incrementing values.
- **STEM/math**: `:stem: latexmath` enables `latexmath:[...]` and `[stem]` blocks (rendered via MathJax/KaTeX in HTML).

## Common Pitfalls & Troubleshooting
- **Bold/italic swapped** vs Markdown — remember `*`=bold, `_`=italic.
- **Code not highlighted** → `:source-highlighter:` unset or the highlighter gem not installed.
- **Admonition renders as plain paragraph** → missing colon (`NOTE:`) or malformed delimited block.
- **Cross-ref shows `[section-id]`** → the target ID doesn't exist or is misspelled.
- **Include not found** → `include::` paths are relative to the *including* file; check `:imagesdir:`/working dir.
- **Table columns wrong** → `cols` spec count must match the number of columns in the body.

## Integration Notes
- **Antora** — multi-repo documentation site generator built on AsciiDoc (versioned docs at scale).
- **DocBook bridge** — convert to DocBook 5 for enterprise toolchains (see docbook.md).
- **Pandoc** — can read/write AsciiDoc for format migration (see pandoc.md), though Asciidoctor is the reference processor.
- **CI**: GitHub/GitLab render `.adoc` natively in repo views.

## Best For / Avoid For
`technical-docs`, `books`, `api-reference`, `multi-format-publishing`, `modular-docs` — choose AsciiDoc when you outgrow Markdown's tables/cross-refs but want plain-text ergonomics.
Avoid for: quick READMEs and chat (use markdown.md), or workflows already standardized on Sphinx/RST (see restructuredtext.md, sphinx.md) or XML validation pipelines (see docbook.md, dita.md).

## See Also
- `markdown.md` — lighter-weight alternative
- `restructuredtext.md`, `sphinx.md` — the Python-world equivalent
- `docbook.md` — AsciiDoc's DocBook backend feeds this toolchain
- `pandoc.md` — convert AsciiDoc to/from other formats
- `../use-case/document-processing.md` — documentation format selection
