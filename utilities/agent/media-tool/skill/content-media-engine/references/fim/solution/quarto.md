# Quarto — Scientific & technical publishing with executable code

Quarto is an open-source publishing system built on Pandoc that renders `.qmd` documents mixing prose, executable code (Python, R, Julia, Observable JS), and rich formatting into HTML, PDF, Word, slides, websites, and books. It is the modern successor to R Markdown, language-agnostic, with first-class cross-references, citations, and reproducible computation.

**Current Version**: Quarto 1.5.x (current major)  **License**: MIT  **Runtime**: standalone `quarto` CLI (bundles Pandoc); code execution needs the language runtime + `jupyter` (Python) or `knitr` (R)

## Official Resources & Documentation
- **Website**: https://quarto.org/
- **Guide**: https://quarto.org/docs/guide/
- **Reference (all options)**: https://quarto.org/docs/reference/
- **Get started**: https://quarto.org/docs/get-started/
- **Gallery**: https://quarto.org/docs/gallery/
- **GitHub**: https://github.com/quarto-dev/quarto-cli

## Installation & Setup
```bash
brew install quarto                 # macOS
# Linux/Windows: download installer from https://quarto.org/docs/get-started/

# Language engines
pip install jupyter matplotlib      # Python execution (jupyter engine)
# R: install.packages("rmarkdown")  # knitr engine

quarto --version
quarto check                        # verify toolchain/engines
```
```bash
quarto render report.qmd                 # infer format from front matter
quarto render report.qmd --to pdf
quarto preview report.qmd                # live-reloading preview
quarto render                            # render a whole project/site/book
```

## Core Document Structure

### Front matter (YAML) + prose + code cells
````markdown
---
title: "Analysis Report"
author: "Data Team"
date: today
format:
  html:
    code-fold: true
    toc: true
    theme: cosmo
  pdf:
    documentclass: report
execute:
  echo: true
  warning: false
  cache: true
bibliography: refs.bib
---

## Introduction

Prose in Markdown. Inline code result: `{python} 2 + 2`.

```{python}
#| label: fig-sine
#| fig-cap: "A sine wave"
import numpy as np, matplotlib.pyplot as plt
x = np.linspace(0, 10, 200)
plt.plot(x, np.sin(x))
plt.show()
```

As shown in @fig-sine, the signal oscillates.
````
Executable cells are fenced with `` ```{lang} ``. Cell options use the `#|` "hashpipe" YAML comment syntax.

### Cell (chunk) execution options
```python
#| echo: false        # hide the code, show output
#| eval: true         # run the cell
#| output: false      # run but hide output
#| warning: false
#| error: true        # keep rendering even if the cell errors
#| include: false     # run, hide both code and output
#| label: fig-plot    # cross-reference id
#| fig-cap: "Caption"
#| fig-width: 8
#| cache: true
```
Set document-wide defaults under `execute:` in the front matter; override per cell with `#|`.

### Cross-references
```markdown
See @fig-sine, @tbl-summary, @eq-quad, and @sec-methods.

## Methods {#sec-methods}

$$ x = \frac{-b \pm \sqrt{b^2-4ac}}{2a} $$ {#eq-quad}
```
Prefixes are meaningful: `fig-`, `tbl-`, `eq-`, `sec-`, `lst-` (listing), `thm-` (theorem). Quarto auto-numbers and links them.

### Callouts (admonitions)
```markdown
::: {.callout-note}
Informational aside.
:::

::: {.callout-warning title="Watch out"}
Something important.
:::
```
Types: `note`, `tip`, `important`, `caution`, `warning`. Add `collapse="true"` for foldable callouts.

### Divs / spans with attributes (Pandoc fenced divs)
```markdown
::: {.column-margin}
Content pushed to the margin.
:::

This is [important text]{.text-danger}.
```

## Output Formats
- **`html`** — with theming, TOC, code folding, tabsets, interactive widgets.
- **`pdf`** — via LaTeX (see latex.md) or `--pdf-engine=typst`.
- **`docx`** — Word (reference-doc styling).
- **`revealjs`** — HTML slides; **`beamer`**/**`pptx`** — PDF/PowerPoint slides.
- **`gfm`/`commonmark`** — Markdown.
- **Projects**: `website`, `book`, `manuscript` (multi-file, with `_quarto.yml`).

## How-To (worked recipes)

### How to theme & add colors (HTML)
Quarto HTML uses **Bootstrap themes** plus optional SCSS overrides — the "add colors/styling" path:
```yaml
---
format:
  html:
    theme:
      - cosmo            # a bundled Bootswatch theme
      - custom.scss      # your overrides
    css: extra.css
    mainfont: "Georgia"
---
```
```scss
/*-- scss:defaults --*/
$primary: #1e6fba;
$body-bg: #ffffff;
$link-color: #1e6fba;

/*-- scss:rules --*/
.callout-note { border-left-color: $primary; }
h1, h2 { color: $primary; }
```
The `/*-- scss:defaults --*/` block sets Bootstrap variables *before* compilation; `/*-- scss:rules --*/` adds CSS *after*. Bundled themes: `cosmo`, `flatly`, `darkly`, `journal`, `litera`, etc.

### How to create a listing / index page
```yaml
---
title: "Blog"
listing:
  contents: posts          # folder of .qmd posts
  type: default            # or grid, table
  sort: "date desc"
  categories: true
  fields: [date, title, description]
---
```
`listing` auto-builds an index from a folder of documents — used for blogs, galleries, and doc hubs.

### How to build a multi-page website or book
```yaml
# _quarto.yml
project:
  type: book            # or website
book:
  title: "My Book"
  chapters:
    - index.qmd
    - intro.qmd
    - part: "Analysis"
      chapters: [data.qmd, model.qmd]
format:
  html: {theme: cosmo}
  pdf: {documentclass: scrbook}
```
```bash
quarto render        # builds the whole project
quarto publish gh-pages   # deploy to GitHub Pages
```

### How to parameterize and cite
```yaml
---
params:
  region: "west"
bibliography: refs.bib
csl: nature.csl
---
```
```python
#| echo: false
region = "west"   # in real use, injected from params
```
```markdown
Prior work established this [@smith2020]. References appear automatically.
```
Render with parameters: `quarto render report.qmd -P region:east`.

## Do's and Don'ts

### ✅ Do
- Put **shared execution defaults** under `execute:` and override per cell with `#|`.
- Use **`label:` with the right prefix** (`fig-`, `tbl-`, …) so `@label` cross-refs work.
- Enable **`cache: true`** for expensive cells during iteration.
- Prefer **`_quarto.yml`** for multi-format/site config over repeating front matter.
- Run **`quarto check`** to diagnose missing engines/toolchain before rendering.

### ❌ Don't
- Don't forget the **`#|` hashpipe** for cell options — plain YAML at the top of a cell won't be parsed as options in all engines.
- Don't expect code execution without the runtime — Python cells need `jupyter`, R cells need `knitr`/`rmarkdown`.
- Don't mismatch the cross-ref prefix and the referenced element (an `@fig-x` must label a figure).
- Don't hardcode a theme in CSS when a **Bootswatch theme + SCSS** does it cleaner.
- Don't commit the `_freeze/`, `.quarto/`, or `_site`/`_book` build artifacts.

## Styling, Theming & Customization
- **HTML**: Bootstrap themes (`theme:`), SCSS overrides (defaults/rules layers), `css:`, `mainfont`, `code-block-bg`, `highlight-style`.
- **Code**: `code-fold`, `code-tools`, `code-line-numbers`, `highlight-style: github`.
- **PDF**: LaTeX template variables (`documentclass`, `geometry`, `include-in-header`).
- **Slides (revealjs)**: `theme`, `transition`, `slide-number`, incremental lists.
- **Layout**: `page-layout: full`, margin columns (`.column-margin`), tabsets (`::: {.panel-tabset}`).

## Advanced Features
- **Freeze**: `execute: {freeze: auto}` caches computation so CI rebuilds don't re-run code.
- **Extensions**: `quarto add <ext>` installs filters, shortcodes, formats, journal templates.
- **Lua filters & shortcodes**: `{{< video ... >}}`, `{{< include file.qmd >}}`, custom `{{< shortcode >}}`.
- **Observable JS**: `{ojs}` cells for reactive, in-browser interactivity without a server.
- **Manuscripts**: `manuscript` project type targets journal submission (JATS, PDF, HTML from one source).
- **Publishing**: `quarto publish` to GitHub Pages, Netlify, Quarto Pub, Posit Connect.

## Common Pitfalls & Troubleshooting
- **Cell options ignored** → missing `#|` prefix or a blank line between options and code.
- **`jupyter`/`knitr` not found** → install the engine; run `quarto check`.
- **Cross-ref shows `?@fig-x`** → the label doesn't exist or the prefix is wrong.
- **PDF fails** → no LaTeX; install TinyTeX (`quarto install tinytex`) or use `format: pdf` with `pdf-engine: typst`.
- **Stale output** → clear `_freeze/`/`.quarto/` or re-render with `--no-cache`.
- **Theme SCSS not applied** → wrong layer marker (`scss:defaults` vs `scss:rules`) or file not listed under `theme:`.

## Integration Notes
- **Pandoc** is the render engine underneath — Quarto extends its Markdown (see pandoc.md).
- **Jupyter** notebooks (`.ipynb`) are a valid input; Quarto renders them directly.
- **R Markdown** projects migrate to Quarto with minimal changes (see r-markdown.md).
- **VS Code / RStudio / Positron** have official Quarto extensions with preview.

## Best For / Avoid For
`scientific-reports`, `reproducible-research`, `data-analysis-docs`, `technical-books`, `multi-format-publishing`, `slides` — choose Quarto when documents mix narrative and executed code and must ship as HTML+PDF+slides from one source.
Avoid for: pure static marketing sites (use hugo.md), simple API docs without computation (mkdocs.md, sphinx.md), or plain READMEs (markdown.md).

## See Also
- `r-markdown.md` — Quarto's predecessor (R-centric)
- `pandoc.md` — the underlying conversion engine
- `markdown.md` — base authoring syntax
- `latex.md`, `typst.md` — PDF backends
- `mkdocs.md`, `sphinx.md`, `hugo.md` — alternative doc/site generators
- `../use-case/document-processing.md`, `../use-case/document-processing.md`
