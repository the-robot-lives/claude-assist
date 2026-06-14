# Jupyter Notebook (.ipynb) - FIM Solution Documentation

## Description
The [Jupyter Notebook](https://nbformat.readthedocs.io) `.ipynb` format is a JSON document interleaving Markdown prose, executable code cells, and rich outputs (tables, plots, HTML). It is the standard medium for reproducible, runnable technical content — tutorials, data analyses, and educational walkthroughs — and exports to HTML, Markdown, PDF, and slides via nbconvert.

## Basic Authoring
```python
# Build a notebook programmatically with nbformat
import nbformat as nbf
nb = nbf.v4.new_notebook()
nb.cells = [
    nbf.v4.new_markdown_cell("# Rate Limiting 101\nA runnable walkthrough."),
    nbf.v4.new_code_cell(
        "import time\n"
        "rate = 10\n"
        "print(f'{rate} req/s')"
    ),
]
nbf.write(nb, "rate_limiting.ipynb")
```
```bash
# Execute and export
jupyter nbconvert --to notebook --execute rate_limiting.ipynb
jupyter nbconvert --to html rate_limiting.ipynb      # or: markdown, pdf, slides
```

## Toolchain
- **nbformat** - Programmatically build/validate `.ipynb` JSON
- **nbconvert** - Execute + export to HTML/Markdown/PDF/reveal slides
- **papermill** - Parameterize and batch-execute notebooks
- **jupytext** - Pair `.ipynb` with `.py`/`.md` for clean diffs/version control
- **jupyter-book / Quarto** - Compile collections of notebooks into sites/books

## Strengths
- Reproducible: prose + code + captured outputs in one artifact
- Rich outputs (DataFrames, Matplotlib/Plotly, HTML widgets)
- Exports to many publishable targets via nbconvert
- Huge ecosystem (Colab, Kaggle, GitHub render `.ipynb` natively)
- Parameterizable (papermill) for templated, data-driven content

## Limitations
- JSON format diffs poorly in Git without jupytext
- Hidden execution-order state can cause non-reproducible runs
- Heavy outputs bloat file size
- Interactive widgets may not survive static export

## Best Use Cases
- Runnable tutorials and data-analysis articles
- Educational/course content with live code
- Reproducible research write-ups shared on GitHub/Colab
- Source for `jupyter-book`/Quarto multi-notebook publications

## NPL-FIM Integration
```npl
⌜jupyter-author|ipynb|FIM@1.0⌝
format: ipynb (nbformat v4)
build: nbformat
execute: nbconvert --execute | papermill
export: html | markdown | pdf | slides
vcs: jupytext-paired
⌞jupyter-author⌟
```

NPL agents author `.ipynb` with nbformat (optionally parameterized via papermill) when content must be runnable and reproducible, then export with nbconvert for publishing.
