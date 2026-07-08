# MkDocs

## What
MkDocs is a fast, simple static site generator written in Python and designed specifically for project documentation. It turns Markdown files into a documentation website with built-in search, navigation, and theming (notably the Material theme).

## How
- The LLM emits Markdown content plus a `mkdocs.yml` config (site name, `theme`, `nav` tree, `plugins`).
- Built with the `mkdocs` CLI: `pip install mkdocs`, `mkdocs new my-project`, `mkdocs serve` for a live-reload dev server at 127.0.0.1:8000, and `mkdocs build` to generate the static site in `site/`.
- Final artifact: a static HTML documentation site with client-side search; deployable to GitHub Pages.

## Why
- Reach for MkDocs for open-source project docs, API docs with code examples, and internal knowledge bases where you want a professional Material-themed site from Markdown only, with minimal YAML config and a rich Python plugin library.
- Tradeoffs: Markdown-only (no RST), no native multi-language support, static-only (no dynamic generation), and fewer layout options than Sphinx.
- Versus Sphinx: MkDocs is simple Markdown-first with fast setup, Sphinx is the Python-docs standard built on reStructuredText with autodoc and more layout power.

## Source
- Solution reference: `fim/solution/mkdocs.md`
