# Sphinx

## What
Sphinx is a documentation generator that produces documentation from source code and reStructuredText. Created for Python documentation, it supports HTML, PDF, ePub, LaTeX, man pages, and plain text, with automatic extraction of docstrings.

## How
- The LLM emits reStructuredText content (`.rst`) plus a `conf.py` config that enables extensions (`sphinx.ext.autodoc`, `napoleon`, `viewcode`, `intersphinx`) and sets `html_theme`.
- Built with the Sphinx CLI: `pip install sphinx`, `sphinx-quickstart docs`, then `make html`; `sphinx-autobuild` gives live rebuilds.
- Final artifact: a searchable static HTML documentation site (plus PDF/ePub/LaTeX/man outputs).

## Why
- Reach for Sphinx for comprehensive Python API reference, library documentation, and multi-format technical manuals where autodoc (docstring extraction), automatic cross-references, intersphinx linking, and professional themes matter.
- Tradeoffs: Python-centric, reStructuredText syntax can be complex, large projects build slowly, and initial configuration can be overwhelming.
- Versus MkDocs: Sphinx is the Python-docs standard on reStructuredText with autodoc and richer output, MkDocs is the simpler Markdown-first alternative.

## Source
- Solution reference: `fim/solution/sphinx.md`
