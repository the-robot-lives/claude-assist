# Org-mode - FIM Solution Documentation

## Description
[Org-mode](https://orgmode.org) is a plain-text markup and authoring format from Emacs for notes, documents, literate programming, and publishing. It supports structured outlines, executable code blocks (Babel), tables with spreadsheet formulas, and export to HTML, LaTeX/PDF, Markdown, ODT, and more.

## Basic Syntax
```org
#+TITLE: Building a Rate Limiter
#+AUTHOR: Keith
#+OPTIONS: toc:2 num:nil

* Overview
Some *bold*, /italic/, =verbatim=, and a [[https://example.com][link]].

** Token Bucket
#+BEGIN_SRC python :results output :exports both
rate = 10
print(f"{rate} req/s")
#+END_SRC

| Algorithm    | Burst | Smooth |
|--------------+-------+--------|
| Token bucket | yes   | yes    |
| Leaky bucket | no    | yes    |
```

## Toolchain
- **Emacs Org** - Native editing, agenda, and export engine
- **org-publish** - Project-based static site generation
- **Pandoc** - Converts Org <-> Markdown/HTML/DOCX/LaTeX outside Emacs
- **ox-hugo** - Export Org subtrees to Hugo-flavored Markdown
- **org-babel** - Literate programming with executable, multi-language blocks

## Strengths
- Outline-first structure with folding and TODO/agenda metadata
- Literate programming: runnable code blocks with captured results
- Built-in table editor with spreadsheet-style formulas
- One source exports to HTML, LaTeX/PDF, ODT, Markdown
- Excellent for reproducible technical notes and knowledge bases

## Limitations
- Strongly tied to the Emacs ecosystem for full feature set
- Smaller audience than Markdown; many platforms lack native rendering
- Babel execution requires local language toolchains
- Export styling needs configuration for polished output

## Best Use Cases
- Literate, reproducible technical articles with embedded runnable code
- Research notes and knowledge bases that later export to a blog
- Authoring pipeline where one source feeds both PDF and web
- Hugo-backed sites via ox-hugo for Emacs-centric writers

## NPL-FIM Integration
```npl
⌜org-author|org|FIM@1.0⌝
format: org-mode
export: html | latex-pdf | markdown | odt
babel: [python, shell, sql]
publish: org-publish | ox-hugo
⌞org-author⌟
```

NPL agents use Org-mode when a deliverable needs literate code execution plus multi-target export from a single plain-text source.
