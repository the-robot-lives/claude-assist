# Markdown — Lightweight plain-text markup (CommonMark + GFM)

Markdown is a plain-text formatting syntax that converts to HTML (and, via converters, to PDF/DOCX/EPUB). Authored by John Gruber (2004); the interoperable baseline is **CommonMark**, and the most widely deployed dialect is **GitHub Flavored Markdown (GFM)**, which adds tables, task lists, strikethrough, and autolinks. Markdown renders anywhere from README files to static-site generators to chat apps.

**Current Spec**: CommonMark 0.31.2 · GFM (living)  **License**: spec is open (CC-BY-SA); parsers vary (MIT common)  **Runtime**: parser-dependent (JS `markdown-it`, C `cmark`, Rust `pulldown-cmark`, Python `markdown`/`mistune`)

## Official Resources & Documentation
- **CommonMark spec**: https://spec.commonmark.org/
- **CommonMark reference / dingus (live tester)**: https://spec.commonmark.org/dingus/
- **GFM spec**: https://github.github.com/gfm/
- **markdown-it (JS, extensible)**: https://github.com/markdown-it/markdown-it
- **marked (JS, fast)**: https://marked.js.org/
- **cmark (C reference impl)**: https://github.com/commonmark/cmark
- **Python-Markdown**: https://python-markdown.github.io/
- **remark / unified (AST toolchain)**: https://unifiedjs.com/
- **Original Gruber syntax**: https://daringfireball.net/projects/markdown/syntax

## Installation & Setup
### JavaScript (npm)
```bash
npm install markdown-it        # extensible, plugin ecosystem
npm install marked             # fast, minimal
npm install remark remark-gfm  # AST / linting / transforms
```
```javascript
import MarkdownIt from 'markdown-it';
const md = new MarkdownIt({ html: false, linkify: true, typographer: true });
const html = md.render('# Hello\n\nSome **bold** text.');
```

### Python (pip)
```bash
pip install markdown           # Python-Markdown (extensions)
pip install mistune            # fast pure-python
```
```python
import markdown
html = markdown.markdown(text, extensions=['tables', 'fenced_code', 'toc'])
```

### CLI (cmark / pandoc)
```bash
cmark README.md > README.html
pandoc -f gfm -t html README.md -o README.html   # see pandoc.md
```

## Core Syntax Reference
The heart of Markdown. Every construct below is CommonMark unless marked **(GFM)**.

### Headings (ATX and Setext)
````markdown
# H1
## H2
### H3 through ###### H6

Setext H1
=========

Setext H2
---------
````
Leave a blank line before a heading. ATX `#` needs a space after it (`#Heading` is literal text).

### Emphasis & inline
````markdown
*italic*  or  _italic_
**bold**  or  __bold__
***bold italic***
~~strikethrough~~          (GFM)
`inline code`
``code with ` backtick``
````

### Lists
````markdown
- unordered (also * or +)
  - nested (indent 2–4 spaces under parent)
1. ordered
2. second      (numbers need not be sequential; first number sets start)
   1. nested ordered

- [ ] task not done   (GFM)
- [x] task done       (GFM)
````
Loose vs tight: a blank line between items makes the list "loose" (items wrapped in `<p>`).

### Links & images
````markdown
[inline link](https://example.com "optional title")
[reference link][ref]
[ref]: https://example.com "title"        (definition anywhere)
<https://autolink.example.com>            (autolink)
![alt text](image.png "title")
[![image link](thumb.png)](full.png)
````

### Blockquotes
````markdown
> quoted line
> > nested quote
>
> continued paragraph
````

### Code blocks
````markdown
```python
def hello():
    return "fenced code with language tag"
```

    indented code block (4 spaces, no language)
````
Always prefer fenced blocks with a language tag — the tag drives syntax highlighting downstream.

### Horizontal rule
````markdown
---
***
___
````

### Tables (GFM)
````markdown
| Left | Center | Right |
|:-----|:------:|------:|
| a    |   b    |     c |
| d    |   e    |     f |
````
Alignment comes from the colon placement in the delimiter row. Tables are GFM, **not** CommonMark — plain CommonMark renderers pass them through as literal text.

### Raw HTML & escapes
````markdown
<div class="note">Block HTML is allowed (if the renderer enables it).</div>

Escape literals with backslash: \*not italic\*  \#not-a-heading
````
HTML is disabled by default in many renderers for security (`html: false`). Do not rely on it for portable docs.

### Footnotes (extension — GFM on GitHub, `pymdownx`, etc.)
````markdown
Here is a claim.[^1]

[^1]: The supporting footnote text.
````

## Supported Output & Dialects
- **CommonMark** — the strict, unambiguous baseline. Target this for portability.
- **GFM** — CommonMark + tables, task lists, strikethrough, autolinks, `<details>` via raw HTML.
- **MDX** — Markdown + JSX components (React docs; see docusaurus/astro).
- **MultiMarkdown / Pandoc Markdown** — footnotes, citations, definition lists, math (see pandoc.md).
- **Renderers that matter**: GitHub/GitLab, VS Code preview, Obsidian, Discourse, Reddit, Slack (a reduced subset — no tables/headings).

## How-To (worked recipes)

### How to add styling / colors to Markdown output
Markdown itself has no color syntax — styling lives in the **CSS applied to the rendered HTML**. Two portable approaches:
````markdown
<!-- 1. Add classes via an extension (e.g. markdown-it-attrs) then style in CSS -->
## Warning {.callout .callout-warning}

<!-- 2. Inline HTML span with a class (renderer must allow HTML) -->
This word is <span class="highlight">highlighted</span>.
````
```css
/* stylesheet paired with the rendered HTML */
.callout-warning { border-left: 4px solid #e8a; background: #fff6f6; padding: .5rem 1rem; }
.highlight { background: #fff3b0; padding: 0 .2em; border-radius: 3px; }
```
Note: never author color as literal HTML `style=` if the doc must survive GitHub's sanitizer — it strips inline styles. Use a class + external CSS in environments you control.

### How to build a documentation admonition / callout
GFM has no native admonition, but GitHub renders this blockquote syntax:
````markdown
> [!NOTE]
> Useful information the reader should know.

> [!WARNING]
> Critical content demanding attention.
````
For other renderers use a plugin (`markdown-it-container`) that maps `::: warning ... :::` to a styled `<div>`.

### How to embed syntax-highlighted code
````markdown
```typescript
const x: number = 42;
```
````
The language tag becomes `class="language-typescript"` on the `<code>` element. Pair with **Prism.js** or **highlight.js** on the page, or a build-time highlighter (`shiki`, `rehype-highlight`).

### How to write a portable cross-reference / anchor
````markdown
See the [installation section](#installation--setup).
````
GitHub slugifies headings: lowercase, spaces→`-`, punctuation dropped, `&`→doubled `-`. `## Installation & Setup` → `#installation--setup`. Verify the exact slug in your renderer; slug rules differ across engines.

## Do's and Don'ts

### ✅ Do
- Target **CommonMark or GFM explicitly** and state which — it eliminates cross-parser ambiguity.
- Put **blank lines around** headings, lists, code fences, and tables — most ambiguity bugs come from missing blank lines.
- Always **tag fenced code blocks** with a language for highlighting.
- Use **reference-style links** for repeated or long URLs to keep prose readable.
- Prefer **fenced** code blocks over indented ones (indented blocks silently break inside lists).

### ❌ Don't
- Don't rely on **tables, task lists, strikethrough, or footnotes** in a plain-CommonMark target — they're GFM/extensions and render as literal text elsewhere.
- Don't hard-wrap paragraphs mid-sentence expecting `<br>` — a single newline is a soft break (space), not a line break. Use two trailing spaces or a `\` for a hard break.
- Don't nest a list under a paragraph without a blank line and correct indentation — it merges into the paragraph.
- Don't embed inline `style=` HTML for GitHub-hosted docs — it's sanitized away.
- Don't assume `# Heading` works without the space after `#`.

## Styling, Theming & Templates
Markdown is content; presentation is entirely the host's concern:
- **GitHub** ships a fixed stylesheet (`github-markdown-css` reproduces it standalone) and sanitizes HTML/CSS.
- **Static-site generators** (see hugo.md, jekyll.md, mkdocs.md) wrap rendered Markdown in themed layouts.
- **`markdown-it` plugins** add capability: `markdown-it-attrs` (classes/IDs), `markdown-it-container` (custom `:::` blocks), `markdown-it-anchor` (heading anchors), `markdown-it-footnote`, `markdown-it-katex` (math).
- For math, most renderers need a plugin bridging to **KaTeX** or **MathJax**: `$inline$` and `$$block$$` are Pandoc/extension syntax, not CommonMark.

## Advanced Features
- **AST manipulation**: `remark`/`unified` parse Markdown → MDAST → transform → stringify or convert to HTML (`rehype`). This is how linters (`remark-lint`), formatters (`prettier`), and MDX work.
- **Frontmatter**: a leading `---\nkey: value\n---` YAML block is not CommonMark but is near-universal in SSGs for metadata (title, date, tags).
- **MDX**: import components and write `<Chart data={...}/>` inline; requires an MDX-aware bundler.
- **Sanitization**: when rendering untrusted Markdown, run output through `DOMPurify` (JS) or `bleach` (Python) — Markdown permits raw HTML and thus XSS if unsanitized.

## Common Pitfalls & Troubleshooting
- **Table renders as literal text** → renderer isn't GFM; enable the tables extension.
- **Underscores inside words** (`file_name_here`) trigger unwanted emphasis in some parsers → GFM's intraword rule suppresses it; escape with `\_` if needed.
- **Nested list flattens** → check indentation is consistent (2–4 spaces) and there's a correct blank-line structure.
- **Code fence "leaks"** → the closing fence must have at least as many backticks as the opening and start the line.
- **Heading anchor 404** → slug algorithm differs per host; copy the anchor the renderer actually emits.
- **HTML stripped** → the renderer has `html: false` or a sanitizer; that's a security default, not a bug.

## Integration Notes
- **Static site generators**: Hugo (`goldmark`), Jekyll (`kramdown`), MkDocs (`python-markdown`), Eleventy, Astro, Docusaurus (MDX). Each pairs Markdown with its own frontmatter + templating — see hugo.md, jekyll.md, mkdocs.md.
- **Livebook/Kino**: Markdown cells render via Earmark (Elixir).
- **Pandoc**: the universal escape hatch for converting Markdown to/from DOCX, LaTeX, RST, etc. — see pandoc.md.

## Best For / Avoid For
`readme`, `docs`, `blogs`, `wikis`, `chat`, `notes`, `ssg-content` — choose Markdown for readable, version-controllable prose with light formatting.
Avoid for: precise print layout, complex multi-column tables, heavy cross-referencing with numbered figures/theorems (use asciidoc.md, restructuredtext.md, latex.md, or typst.md), or anything needing validated structured semantics (use docbook.md / dita.md).

## See Also
- `asciidoc.md`, `restructuredtext.md` — richer text markup with native tables, admonitions, cross-refs
- `pandoc.md` — convert Markdown to/from 40+ formats
- `hugo.md`, `jekyll.md`, `mkdocs.md`, `quarto.md` — static-site generators consuming Markdown
- `r-markdown.md`, `quarto.md` — Markdown + executable code
- `../use-case/document-processing.md` — choosing a documentation format
