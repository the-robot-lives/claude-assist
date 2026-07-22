# R Markdown

## What
R Markdown combines R code with Markdown to create reproducible documents and reports, integrating code execution with narrative text for data-analysis workflows. It renders to multiple formats via knitr and pandoc.

## How
- The LLM emits an `.rmd` document: YAML front matter (`title`, `output`) plus Markdown with ```` ```{r} ```` code chunks (e.g. `knitr::opts_chunk$set(echo = TRUE)`, data loading, ggplot visualizations) that execute at render time.
- Rendered via the `rmarkdown` package (`install.packages("rmarkdown")`), typically from RStudio; chunk-level caching speeds long computations and reports can be parameterized for automation.
- Final artifact: HTML, PDF, Word, or presentations (with Shiny for interactivity).

## Why
- Reach for R Markdown for statistical analysis reports, research papers with embedded analysis, and reproducible R-centric workflows where code and results live in one document.
- Tradeoffs: primarily designed for R, build times can be slow for complex documents, requires R and pandoc, and binary outputs challenge Git workflows.
- Versus Quarto it is the R-focused predecessor; Quarto generalizes the same reproducible-document model to Python/Julia/Observable as well.

## Source
- Solution reference: `fim/solution/r-markdown.md`
