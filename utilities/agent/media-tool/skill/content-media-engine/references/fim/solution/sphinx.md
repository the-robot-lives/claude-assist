# Sphinx — Documentation generator for Python & beyond

Sphinx turns reStructuredText (and, via MyST, Markdown) source into cross-referenced HTML, PDF, EPUB, and man-page documentation. Built for Python's own docs, it adds domains, autodoc (docstring extraction), a rich extension ecosystem, themes, and full-text search on top of Docutils/RST. It is the default for library documentation and the engine behind Read the Docs.

**Current Version**: Sphinx 7.x (current major)  **License**: BSD-2-Clause  **Runtime**: Python 3.9+ (`sphinx`); build via `sphinx-build`/`make`

## Official Resources & Documentation
- **Sphinx docs**: https://www.sphinx-doc.org/
- **Getting started / tutorial**: https://www.sphinx-doc.org/en/master/tutorial/
- **conf.py reference**: https://www.sphinx-doc.org/en/master/usage/configuration.html
- **Directives**: https://www.sphinx-doc.org/en/master/usage/restructuredtext/directives.html
- **Domains**: https://www.sphinx-doc.org/en/master/usage/domains/index.html
- **MyST (Markdown)**: https://myst-parser.readthedocs.io/
- **Read the Docs**: https://docs.readthedocs.io/
- **Themes gallery**: https://sphinx-themes.org/

## Installation & Setup
```bash
pip install sphinx
pip install sphinx-autobuild furo myst-parser   # live rebuild, theme, Markdown

sphinx-quickstart docs        # scaffold conf.py, index.rst, Makefile
cd docs
make html                     # -> _build/html
make latexpdf                 # -> PDF (needs LaTeX; see latex.md)
sphinx-autobuild . _build/html   # live-reloading dev server
```

## Core Configuration (conf.py)
```python
project = 'MyProject'
author = 'Your Name'
copyright = '2024, Your Name'
release = '2.1.0'

extensions = [
    'sphinx.ext.autodoc',      # pull docs from docstrings
    'sphinx.ext.autosummary',  # generate stub pages per API object
    'sphinx.ext.napoleon',     # Google/NumPy docstring styles
    'sphinx.ext.viewcode',     # link to highlighted source
    'sphinx.ext.intersphinx',  # cross-link other projects' docs
    'sphinx.ext.todo',
    'myst_parser',             # allow Markdown (.md) sources
]

html_theme = 'furo'                    # or sphinx_rtd_theme, alabaster, pydata_sphinx_theme
html_static_path = ['_static']
html_css_files = ['custom.css']

autodoc_member_order = 'bysource'
autosummary_generate = True
napoleon_google_docstring = True

intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'numpy': ('https://numpy.org/doc/stable/', None),
}
source_suffix = {'.rst': 'restructuredtext', '.md': 'markdown'}
```
`extensions` is the heart of Sphinx configuration — nearly every feature (autodoc, math, diagrams, Markdown) is an extension you enable here.

## Core Structure & Directives

### toctree (navigation spine)
```rst
.. toctree::
   :maxdepth: 2
   :caption: Contents

   installation
   usage
   api/index
   changelog
```
`toctree` in `index.rst` defines the document tree, navigation, and next/prev links. Every page should be reachable from a toctree or Sphinx warns about orphans.

### Autodoc (docstring → docs)
```rst
.. automodule:: mypackage.core
   :members:
   :undoc-members:
   :show-inheritance:

.. autoclass:: mypackage.Client
   :members:
   :special-members: __init__

.. autofunction:: mypackage.connect
```
Autodoc imports the module at build time and renders its docstrings. `napoleon` lets you write Google/NumPy-style docstrings instead of raw RST field lists.

### Domains & cross-references
```rst
.. py:function:: connect(host, port=5432)

   :param host: server hostname
   :param port: TCP port
   :returns: a Connection
   :rtype: Connection

Use :py:func:`connect` or the target :ref:`quickstart` / :doc:`/guide/install`.
```
Roles: `:ref:` (labels), `:doc:` (whole documents), `:py:class:`/`:py:func:`/`:py:meth:` (Python objects), `:term:` (glossary). Cross-references survive renames because they resolve by identifier, not path.

### Admonitions, code, math
```rst
.. note::
   Enabled by default.

.. code-block:: python
   :linenos:
   :emphasize-lines: 2

   import mypackage
   client = mypackage.Client()

.. math::

   \int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}
```

### Directives you'll reuse
`.. versionadded::`, `.. versionchanged::`, `.. deprecated::`, `.. seealso::`, `.. glossary::`, `.. index::`, `.. include::`, `.. literalinclude:: file.py`.

## Output Builders
- `html` (default), `dirhtml`, `singlehtml`
- `latex` → `latexpdf` (PDF via LaTeX; see latex.md)
- `epub`
- `man` (Unix man pages)
- `text`, `json`, `xml`
- `linkcheck` (validate external URLs)
Run any builder: `sphinx-build -b <builder> source _build/<builder>`.

## How-To (worked recipes)

### How to theme & add custom CSS / colors
Pick a theme, then layer custom CSS registered from `conf.py`:
```python
# conf.py
html_theme = 'furo'
html_static_path = ['_static']
html_css_files = ['custom.css']
html_theme_options = {                 # furo supports light/dark palette overrides
    'light_css_variables': {'color-brand-primary': '#1e6fba',
                            'color-brand-content': '#1e6fba'},
    'dark_css_variables':  {'color-brand-primary': '#7cb7ff'},
}
```
```css
/* docs/_static/custom.css */
.rst-content .admonition.note { border-left-color: #1e6fba; }
code.literal { background: #f5f7fa; color: #c0392b; }
```
Theme options handle brand colors declaratively; `custom.css` covers anything the theme doesn't expose. This is the "add colors/styling" path for Sphinx.

### How to auto-generate an API reference
```python
# conf.py
extensions += ['sphinx.ext.autosummary']
autosummary_generate = True
```
```rst
.. autosummary::
   :toctree: _autosummary
   :recursive:

   mypackage
```
`autosummary` walks the package and emits a stub page per module/class/function — the standard way to build a complete API reference with minimal hand-authoring.

### How to embed diagrams
```python
extensions += ['sphinxcontrib.mermaid']   # pip install sphinxcontrib-mermaid
```
```rst
.. mermaid::

   graph TD
     A[Client] --> B[API]
     B --> C[(Database)]
```
Alternatives: `sphinx.ext.graphviz` (`.. graphviz::`), `sphinxcontrib-plantuml`.

### How to cross-link another project's docs
```python
intersphinx_mapping = {'requests': ('https://requests.readthedocs.io/en/latest/', None)}
```
```rst
See :py:class:`requests.Session` — the link resolves into the requests docs.
```

## Do's and Don'ts

### ✅ Do
- Register every page in a **`toctree`** to avoid orphan warnings and get navigation.
- Use **`napoleon`** so contributors write natural Google/NumPy docstrings.
- Add **`myst_parser`** if the team prefers Markdown — you keep directives via MyST syntax.
- Treat **warnings as errors in CI** (`sphinx-build -W`) to catch broken references early.
- Use **`intersphinx`** rather than hardcoding URLs to external API docs.

### ❌ Don't
- Don't let autodoc fail silently — the package must be **importable** at build time (install it or set `sys.path` in `conf.py`).
- Don't forget **`html_static_path`** before `html_css_files`, or your CSS won't be copied.
- Don't hand-maintain API pages when **`autosummary`/`automodule`** can generate them.
- Don't mismatch RST title adornments (see restructuredtext.md) — Sphinx inherits Docutils' strictness.
- Don't commit `_build/` — it's generated output.

## Styling, Theming & Templates
- **Themes**: `furo` (modern, dark mode), `sphinx_rtd_theme` (Read the Docs classic), `pydata_sphinx_theme` (scientific), `alabaster` (default), `book-theme`.
- **`html_theme_options`**: per-theme knobs (colors, logo, nav depth).
- **`html_static_path` + `html_css_files`/`html_js_files`**: inject assets.
- **Custom templates**: override Jinja2 templates in `_templates/` (e.g. `layout.html`, `page.html`).
- **`html_logo`, `html_favicon`, `html_title`**: branding.

## Advanced Features
- **`sphinx.ext.doctest`** — run and verify code examples during the build.
- **`sphinx.ext.autosectionlabel`** — auto-create `:ref:` labels for every section title.
- **`sphinx-multiversion`** / RTD versions — build docs for multiple tags/branches.
- **`sphinx.ext.ifconfig`** and tags — conditional content per build.
- **Custom directives/roles** — register Python classes to add new constructs.
- **`linkcheck` builder** — CI job that flags dead external links.
- **`sphinx-intl`** — translation workflow (gettext catalogs).

## Common Pitfalls & Troubleshooting
- **`autodoc: failed to import module`** → package not installed in the build env or missing `sys.path.insert(0, os.path.abspath('..'))` in `conf.py`.
- **"document isn't included in any toctree"** → add the page to a `toctree`.
- **CSS changes ignored** → file not under `html_static_path`, or browser cache; rebuild clean (`make clean html`).
- **`:ref:` broken** → label undefined or points to a non-title; enable `autosectionlabel` for section refs.
- **PDF build fails** → missing LaTeX packages (see latex.md); check `make latexpdf` log.
- **Slow builds** → disable `viewcode`/heavy extensions during drafting; use `sphinx-autobuild` incremental.

## Integration Notes
- **Read the Docs** builds Sphinx projects automatically from a repo + `.readthedocs.yaml`.
- **MyST** lets you author in Markdown while keeping Sphinx directives/roles (see markdown.md, restructuredtext.md).
- **Pandoc** can convert existing docs into RST/Markdown for Sphinx ingestion (see pandoc.md).
- **PDF** output goes through LaTeX (see latex.md).

## Best For / Avoid For
`python-docs`, `api-reference`, `library-docs`, `technical-manuals`, `versioned-docs` — choose Sphinx for code-adjacent documentation with autodoc, strong cross-references, and multi-format output.
Avoid for: marketing sites or blogs (use hugo.md, jekyll.md), single-file READMEs (markdown.md), or teams wanting the absolute simplest Markdown-only setup (mkdocs.md).

## See Also
- `restructuredtext.md` — Sphinx's primary source language
- `mkdocs.md` — simpler Markdown-only documentation generator
- `markdown.md` — via MyST, an alternative source format
- `latex.md` — PDF backend
- `pandoc.md` — convert legacy docs into Sphinx sources
- `../use-case/document-processing.md`
