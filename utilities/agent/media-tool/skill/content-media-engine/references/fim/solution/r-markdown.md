# R Markdown — Reproducible documents with embedded R (knitr + Pandoc)

R Markdown weaves narrative Markdown with executable **R** (and Python, SQL, Bash) code chunks into reproducible reports, rendered via **knitr** → Markdown → **Pandoc** to HTML, PDF, Word, slides, and dashboards. Code, results, tables, and figures are generated at render time, so the document always reflects the current data. It remains the workhorse of the R data-science world (and the conceptual parent of Quarto).

**Current Version**: `rmarkdown` 2.x + `knitr` 1.x (current)  **License**: GPL-3  **Runtime**: R + `rmarkdown` + Pandoc (bundled with RStudio); PDF needs LaTeX/TinyTeX

## Official Resources & Documentation
- **R Markdown site**: https://rmarkdown.rstudio.com/
- **The definitive guide (book)**: https://bookdown.org/yihui/rmarkdown/
- **knitr chunk options**: https://yihui.org/knitr/options/
- **Cookbook**: https://bookdown.org/yihui/rmarkdown-cookbook/
- **CRAN**: https://cran.r-project.org/package=rmarkdown
- **Gallery**: https://rmarkdown.rstudio.com/gallery.html

## Installation & Setup
```r
install.packages("rmarkdown")
install.packages("knitr")
tinytex::install_tinytex()     # lightweight LaTeX for PDF output
# Optional engines
install.packages("reticulate") # Python chunks
```
Render from R or the shell:
```r
rmarkdown::render("report.Rmd")                    # uses output: in YAML
rmarkdown::render("report.Rmd", output_format = "pdf_document")
```
```bash
Rscript -e 'rmarkdown::render("report.Rmd")'
```
RStudio's **Knit** button calls the same pipeline.

## Core Document Structure

### YAML header + prose + code chunks
````markdown
---
title: "Analysis Report"
author: "Data Team"
date: "`r Sys.Date()`"
output:
  html_document:
    toc: true
    code_folding: hide
    theme: cosmo
params:
  region: "west"
---

## Introduction

Inline result: the mean is `r round(mean(mtcars$mpg), 1)`.

```{r setup, include=FALSE}
library(tidyverse)
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
```

```{r plot, fig.width=8, fig.cap="MPG vs weight"}
ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_minimal()
```
````
Chunks are delimited by `` ```{r label, options} ``. Inline code uses `` `r expr` ``. The `setup` chunk conventionally sets global options via `knitr::opts_chunk$set()`.

### Chunk options (knitr)
```r
# Common options set per-chunk or globally:
echo = TRUE       # show the code
eval = TRUE       # run the code
include = FALSE   # run but hide code AND output
results = 'hide'  # 'markup' | 'asis' | 'hold' | 'hide'
warning = FALSE   # suppress warnings
message = FALSE   # suppress messages
fig.width = 8; fig.height = 5; fig.cap = "Caption"; fig.align = 'center'
out.width = "80%"
cache = TRUE      # cache expensive chunks
error = TRUE      # keep rendering even if the chunk errors
```
Set defaults once with `knitr::opts_chunk$set(...)`; override per chunk in the header.

### Multi-language chunks
````markdown
```{python}
import numpy as np
print(np.arange(5))
```

```{sql, connection=con}
SELECT * FROM users LIMIT 5;
```

```{bash}
echo "shell output"
```
````
knitr supports many engines (`python` via reticulate, `sql`, `bash`, `stan`, `sql`, `js`); Python objects can cross into R via `reticulate`.

## Output Formats
- **`html_document`** — TOC, themes, code folding, tabsets, floating TOC.
- **`pdf_document`** — via LaTeX (see latex.md); TinyTeX recommended.
- **`word_document`** — Word (reference-docx styling).
- **`ioslides_presentation` / `slidy_presentation` / `beamer_presentation` / `revealjs::revealjs_presentation`** — slides.
- **`bookdown::gitbook` / `pdf_book`** — multi-chapter books.
- **`flexdashboard::flex_dashboard`** — dashboards.
- **`github_document`** — GitHub-friendly Markdown.

## How-To (worked recipes)

### How to theme & add colors (HTML)
`html_document` accepts a Bootswatch **theme** plus a custom CSS file; deeper control uses the `bslib` engine:
````markdown
---
output:
  html_document:
    theme: cosmo          # bootswatch theme
    highlight: tango       # code highlighting style
    css: styles.css
---
````
```css
/* styles.css */
h1, h2 { color: #1e6fba; }
.tocify-item.active { background: #1e6fba; }
pre { background: #f5f7fa; border-left: 3px solid #1e6fba; }
```
For Bootstrap 5 + programmatic theming:
````markdown
---
output:
  html_document:
    theme:
      bootswatch: flatly
      primary: "#1e6fba"
      base_font: {google: "Source Sans Pro"}
---
````
`theme:` as a nested map invokes **bslib**, exposing Bootstrap variables (`primary`, fonts) directly — the modern "add colors/styling" path. For plot colors, set a ggplot theme in the setup chunk.

### How to control figure output
````markdown
```{r, fig.width=10, fig.height=4, out.width="100%", fig.cap="Trend", dpi=150}
plot(cumsum(rnorm(100)), type = "l")
```
````
`fig.*` options control the generated image; `out.width` controls display size in the rendered doc.

### How to parameterize a report
````markdown
---
params:
  region: "west"
  date: !r Sys.Date()
---

```{r}
subset <- sales[sales$region == params$region, ]
```
````
```r
rmarkdown::render("report.Rmd", params = list(region = "east"))
```
Parameterized reports let one `.Rmd` generate many tailored outputs (per region/client/date).

### How to add citations
````markdown
---
bibliography: refs.bib
csl: nature.csl
link-citations: true
---

Prior work established this [@smith2020]. References render automatically.
````
Pandoc's citeproc (see pandoc.md) formats `[@key]` and appends a reference list.

## Do's and Don'ts

### ✅ Do
- Put a **`setup` chunk** with `knitr::opts_chunk$set()` at the top for global defaults.
- Use **`cache = TRUE`** on slow chunks during iteration (invalidate when inputs change).
- Keep the document **self-contained** — load data/libraries inside chunks so it renders from a clean session.
- Use **`params`** for reusable, automated reporting.
- Prefer **TinyTeX** over a full TeX install for PDF (`tinytex::install_tinytex()`).

### ❌ Don't
- Don't rely on your **interactive session's state** — render in a fresh R session (RStudio's Knit does this) so results are reproducible.
- Don't forget **`include=FALSE`** on setup/library chunks you don't want printed.
- Don't expect PDF without **LaTeX** installed.
- Don't commit rendered binaries (HTML/PDF/Word) as the source of truth — the `.Rmd` is the source.
- Don't let a broken chunk halt the build unnoticed — use `error=TRUE` deliberately, not accidentally.

## Styling, Theming & Customization
- **HTML**: `theme` (Bootswatch or `bslib` map), `highlight`, `css`, `toc_float`, `code_folding`, `df_print: paged`.
- **PDF**: LaTeX options in YAML (`documentclass`, `geometry`, `header-includes`) — see latex.md.
- **Word**: `reference_docx` supplies named styles (see pandoc.md).
- **Code highlighting**: `highlight:` (tango, pygments, kate, espresso, zenburn, breezedark).
- **Plots**: styled in R (ggplot2 themes, palettes) inside chunks — the figure image carries its own colors.

## Advanced Features
- **`bookdown`** — multi-chapter books/theses with numbered cross-references (`\@ref(fig:label)`).
- **`flexdashboard`** — dashboards laid out by Markdown headers.
- **`blogdown`** — websites (Hugo-backed) with R Markdown content (see hugo.md).
- **`xaringan`** — HTML slides (remark.js).
- **Child documents** — `knitr::knit_child()` / `child=` to compose from parts.
- **Caching & dependencies** — `cache.extra`, `dependson` for correct invalidation.
- **`reticulate`** — share objects between R and Python chunks.

## Common Pitfalls & Troubleshooting
- **PDF fails ("LaTeX not found")** → `tinytex::install_tinytex()`.
- **Object not found on knit** → relied on interactive session state; add the code to a chunk.
- **Stale results** → cached chunk not invalidated; clear the `*_cache/` dir or change `cache.extra`.
- **Plot too small/large** → adjust `fig.width`/`out.width`.
- **Chunk options ignored** → malformed header (spaces/commas) inside `` ```{r ...} ``.
- **Encoding issues in PDF** → use XeLaTeX (`latex_engine: xelatex`) with a Unicode font.

## Integration Notes
- **Pandoc** is the final render step (Markdown → output); many YAML options map to Pandoc (see pandoc.md).
- **Quarto** is the multi-language successor — most `.Rmd` files port to `.qmd` with minor changes (see quarto.md).
- **RStudio/Positron** provide inline preview and one-click Knit.
- **CI**: `Rscript -e 'rmarkdown::render(...)'` renders headlessly.

## Best For / Avoid For
`statistical-reports`, `reproducible-research`, `data-science-docs`, `automated-reporting`, `r-workflows` — choose R Markdown when the analysis lives in R and the document must regenerate from data.
Avoid for: non-R teams or polyglot projects (prefer quarto.md), pure prose docs (markdown.md), or general websites (hugo.md, jekyll.md).

## See Also
- `quarto.md` — the modern, language-agnostic successor
- `pandoc.md` — the rendering engine underneath
- `markdown.md` — base authoring syntax
- `latex.md` — PDF backend
- `../use-case/document-processing.md`, `../use-case/document-processing.md`
