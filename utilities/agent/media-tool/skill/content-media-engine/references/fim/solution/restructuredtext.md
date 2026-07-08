# reStructuredText (RST) — Extensible markup for Python & technical docs

reStructuredText is a plain-text markup language with a formal, extensible directive/role system. It is the parser core of **Docutils** and the authoring language of **Sphinx**, making it the de-facto standard for Python project documentation. Unlike Markdown, RST is designed for extension: directives (`.. name::`) and roles (`:name:`) add arbitrary structured constructs, and Sphinx layers domains, cross-references, and autodoc on top.

**Current Version**: Docutils 0.21.x · Sphinx 7.x (current major)  **License**: Docutils public-domain/BSD; Sphinx BSD  **Runtime**: Python (`docutils`, `sphinx`)

## Official Resources & Documentation
- **Docutils / RST home**: https://docutils.sourceforge.io/rst.html
- **RST quick reference**: https://docutils.sourceforge.io/docs/user/rst/quickref.html
- **RST spec**: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html
- **Directives reference**: https://docutils.sourceforge.io/docs/ref/rst/directives.html
- **Roles reference**: https://docutils.sourceforge.io/docs/ref/rst/roles.html
- **Sphinx**: https://www.sphinx-doc.org/ (see sphinx.md)
- **MyST (Markdown-flavored RST for Sphinx)**: https://myst-parser.readthedocs.io/

## Installation & Setup
```bash
pip install docutils        # standalone RST tools
pip install sphinx          # full doc generator (see sphinx.md)
```
Standalone conversion:
```bash
rst2html5 document.rst output.html
rst2latex document.rst output.tex
rst2man   document.rst output.1
```
Python API:
```python
from docutils.core import publish_string
html = publish_string(source=rst_text, writer_name='html5').decode('utf-8')
```

## Core Syntax Reference

### Section titles (adornment-based)
```rst
================
Document Title
================

Chapter
=======

Section
-------

Subsection
~~~~~~~~~~
```
Titles are underlined (optionally overlined) with punctuation. The **adornment character sequence establishes hierarchy by order of first appearance** — there is no fixed mapping, but a common convention is `#` (parts, with overline), `*` (chapters), `=`, `-`, `~`, `^`. Be consistent.

### Inline markup
```rst
**bold**  *emphasis*  ``inline literal / code``
`interpreted text with a role`:role:
:sub:`subscript`  :sup:`superscript`
Standalone link: https://example.com
```
Inline markup must be separated from surrounding text by whitespace or punctuation; escape with backslash where needed.

### Lists
```rst
- bullet item
- another
  continued on next line (aligned to text)

1. enumerated
#. auto-numbered
   a. nested letter

term
   definition (definition list: term, then indented body)

:field name: field body (field list)
```

### Literal & code blocks
```rst
Plain literal block::

    indented verbatim text after the ``::`` marker

.. code-block:: python
   :linenos:
   :emphasize-lines: 2

   def example():
       return True
```
`::` at the end of a paragraph starts an indented literal block. `.. code-block::` (Sphinx/newer Docutils) adds language highlighting and options.

### Directives (the extension mechanism)
```rst
.. directive-name:: argument
   :option: value
   :another: value

   Directive content (indented).
```
Built-in directives include `note`, `warning`, `image`, `figure`, `table`, `code-block`, `math`, `contents` (TOC), `include`, `raw`, `topic`, `sidebar`, `admonition` (custom-titled).

### Admonitions
```rst
.. note::
   Informational aside.

.. warning::
   Something to watch out for.

.. admonition:: Custom Title
   :class: tip

   Body of a custom admonition.
```

### Roles (inline extensions)
```rst
:math:`\alpha^2 + \beta^2`
:pep:`8`                          (Docutils/Sphinx)
:ref:`label-name`                 (Sphinx cross-ref)
:doc:`/guide/install`             (Sphinx doc link)
:class:`~package.module.MyClass`  (Sphinx Python domain)
```

### Images, figures, tables
```rst
.. image:: diagram.png
   :width: 600px
   :alt: Architecture diagram

.. figure:: chart.png
   :align: center

   Caption text becomes the figure caption.

.. list-table:: Pricing
   :header-rows: 1
   :widths: 10 40 20

   * - ID
     - Description
     - Price
   * - 1
     - Widget
     - 9.99
```
`list-table` is far easier to author (and diff) than RST's grid/simple ASCII tables.

### Cross-references & links
```rst
.. _my-label:

Target Section
==============

See my-label_ or, in Sphinx, :ref:`my-label`.

External `link text <https://example.com>`_
```

### Comments & math
```rst
.. This is a comment; it never renders.

.. math::

   \frac{\partial u}{\partial t} = \alpha \nabla^2 u

Inline: :math:`e^{i\pi} + 1 = 0`
```

## Sphinx Domains & Directives (why RST scales)
Sphinx extends RST with **domains** — namespaced directives/roles for describing code:
```rst
.. py:function:: connect(host, port=5432)

   Open a connection.

   :param host: server hostname
   :param port: TCP port
   :returns: a connection object
   :raises ConnectionError: on failure

Reference it with :py:func:`connect`.
```
Domains ship for Python (`py`), C (`c`), C++ (`cpp`), JavaScript (`js`), and reStructuredText itself. `autodoc` generates these directives from live docstrings — see sphinx.md.

## How-To (worked recipes)

### How to style / color output (custom directive classes + CSS)
RST has no color syntax; styling comes from **CSS classes** applied via the `:class:` option or the `.. role::` directive, then styled in the theme's CSS:
```rst
.. role:: red

This word is :red:`important`.

.. admonition:: Deprecated
   :class: danger

   This API will be removed in v3.
```
```css
/* _static/custom.css, registered via html_css_files in conf.py */
.red { color: #c0392b; font-weight: bold; }
.admonition.danger { border-left: 4px solid #c0392b; background: #fdf0ef; }
```
In Sphinx, register the CSS with `html_css_files = ['custom.css']` in `conf.py`. Defining a named role once and reusing it keeps color out of the prose.

### How to embed highlighted, line-numbered code
```rst
.. code-block:: python
   :linenos:
   :emphasize-lines: 3
   :caption: connection.py

   import psycopg2

   conn = psycopg2.connect(dsn)   # highlighted line
```
Sphinx uses Pygments; set the default language with `highlight_language` in `conf.py`.

### How to include and reuse content
```rst
.. include:: /shared/disclaimer.rst

.. |product| replace:: Acme Cloud
.. |version| replace:: 2.1

Welcome to |product| |version|.
```
`.. include::` pulls in another file; substitution definitions (`|name|`) create reusable inline snippets.

### How to build a cross-referenced API section
```rst
.. _database-api:

Database API
============

.. py:class:: Connection

   .. py:method:: execute(sql)

      Run a statement. See :ref:`database-api` for context.
```

## Do's and Don'ts

### ✅ Do
- Keep **adornment characters consistent** across the whole project (pick a fixed order and document it).
- Prefer **`list-table`** over grid/simple tables — the ASCII-art tables are painful to maintain.
- Use **`:ref:` and `:doc:`** (Sphinx) for cross-references so links survive renames.
- Indent directive content and options with a consistent width (3 spaces aligns under `.. `).
- Use **substitutions** (`|name|`) for product names/versions reused throughout.

### ❌ Don't
- Don't mismatch title underline length — it must be **at least as long as the title text**, or Docutils warns/errors.
- Don't forget the **blank line** between a directive's options and its content — options run together with the body otherwise.
- Don't use tabs for indentation — RST is whitespace-sensitive and tabs cause misparsing.
- Don't nest inline markup (`**\`code\`**` won't work); RST inline markup does not nest.
- Don't assume Markdown habits — `#` is not a heading, `-` list items need a following space, and `> ` is not a blockquote.

## Styling, Theming & Templates
- **Docutils standalone**: pass `--stylesheet=custom.css` to `rst2html5`.
- **Sphinx** (the usual path): themes (`sphinx_rtd_theme`, `furo`, `alabaster`, `pydata-sphinx-theme`) control layout; `html_css_files`/`html_static_path` inject custom CSS. See sphinx.md for full theming.
- **Custom directives/roles**: register Python classes with Docutils/Sphinx to add new block/inline constructs and their rendering — the core reason RST is chosen for large, structured docs.

## Advanced Features
- **`autodoc` / `autosummary`** (Sphinx): generate API docs from docstrings.
- **`intersphinx`**: cross-link into other projects' docs (`:py:class:` resolves across projects).
- **Doctest** (`.. doctest::`): execute and verify example code during the build.
- **MyST**: write Sphinx docs in Markdown while keeping directive/role power — a bridge for Markdown-native teams.
- **Bibliographies**: `sphinxcontrib-bibtex` adds `:cite:` roles and reference lists.

## Common Pitfalls & Troubleshooting
- **"Title underline too short"** → extend the adornment to cover the full title width.
- **Directive content ignored** → missing blank line between the directive line/options and the content, or under-indented content.
- **`:ref:` produces `?`** → the label isn't defined (`.. _label:` before a section) or the target isn't a section title.
- **Inline literal breaks** → backtick counts unbalanced, or markup not whitespace-separated.
- **Tables mangled** → column borders in grid tables misaligned; switch to `list-table`.
- **Code not highlighted** → wrong language name or Pygments lexer missing.

## Integration Notes
- **Sphinx** is the primary consumer — most RST is authored *for* Sphinx (see sphinx.md).
- **Read the Docs** builds Sphinx/RST projects with zero config.
- **Pandoc** reads/writes RST for migration to/from Markdown, DocBook, etc. (see pandoc.md).
- **Docstrings**: NumPy/Google styles are converted to RST fields by `sphinx.ext.napoleon`.

## Best For / Avoid For
`python-docs`, `api-reference`, `sphinx-sites`, `technical-manuals`, `cross-referenced-docs` — choose RST when building Sphinx documentation or when you need a rigorously extensible markup with strong cross-referencing.
Avoid for: quick READMEs/blogs (use markdown.md), non-Python ecosystems that prefer AsciiDoc (see asciidoc.md), or teams that resist whitespace-sensitive syntax (consider MyST Markdown or asciidoc.md).

## See Also
- `sphinx.md` — the documentation generator built on RST
- `markdown.md` — lighter alternative; MyST bridges the two
- `asciidoc.md` — comparable semantic markup outside the Python world
- `pandoc.md` — convert RST to/from other formats
- `../use-case/document-processing.md` — documentation format selection
