# reStructuredText

## What
reStructuredText (RST) is an extensible markup language for Python documentation and technical writing, developed as part of the Docutils project. It is the standard format for Python documentation through its integration with Sphinx.

## How
- The LLM emits RST text (`.rst`): underlined section titles, `**bold**`/`*italic*`, `.. code-block:: python` directives, `:doc:`/`:ref:` cross-reference roles, `.. note::` admonitions, and `.. math::`.
- Rendered by Docutils, or (for advanced features) by Sphinx, which adds autodoc from docstrings, cross-referencing, and multiple output formats via an extension system.
- Final artifact: HTML, PDF, or EPUB (typically through Sphinx).

## Why
- Reach for RST for Python project and API documentation, technical manuals needing rich cross-references, and scientific/mathematical docs — it is highly extensible through directives and roles and is the Python ecosystem standard.
- Tradeoffs: steeper learning curve than Markdown, verbose and strict syntax, indentation-sensitive, limited adoption outside Python, and advanced features require Sphinx.
- It is the markup that powers Sphinx; versus Markdown (as used by MkDocs) it trades simplicity for semantic richness and cross-referencing depth.

## Source
- Solution reference: `fim/solution/restructuredtext.md`
