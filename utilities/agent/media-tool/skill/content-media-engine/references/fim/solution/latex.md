# LaTeX — Professional typesetting & document preparation system

LaTeX is a macro package over Donald Knuth's TeX engine, the standard for typesetting mathematics, scientific papers, theses, and books. Authors write plain-text markup; the engine produces precisely laid-out PDF (or DVI/PS). LaTeX excels at math, automatic numbering/cross-referencing, bibliographies, and multi-hundred-page documents with consistent structure. It is the lingua franca of academic publishing.

**Current Version**: LaTeX2e (2024 release) · engines: pdfTeX, XeTeX, LuaTeX  **License**: LPPL  **Runtime**: TeX distribution (TeX Live, MiKTeX, MacTeX); build tool `latexmk`

## Official Resources & Documentation
- **LaTeX project**: https://www.latex-project.org/
- **CTAN (package archive)**: https://ctan.org/
- **Overleaf docs (excellent tutorials)**: https://www.overleaf.com/learn
- **TeX Live**: https://tug.org/texlive/
- **wikibooks LaTeX**: https://en.wikibooks.org/wiki/LaTeX
- **TeX StackExchange**: https://tex.stackexchange.com/
- **Overleaf (browser IDE)**: https://www.overleaf.com/

## Installation & Setup
```bash
# Linux (full ~5GB) / minimal
apt-get install texlive-full
apt-get install texlive-latex-base texlive-latex-extra texlive-fonts-recommended

# macOS
brew install --cask mactex          # full
brew install --cask basictex        # minimal, add packages via tlmgr

# Package manager for TeX itself
tlmgr install <package>
```
Build with `latexmk` (handles multi-pass runs, bibliography, and reruns automatically):
```bash
latexmk -pdf document.tex           # pdfTeX
latexmk -xelatex document.tex       # XeTeX (system fonts, Unicode)
latexmk -lualatex document.tex      # LuaTeX
latexmk -c                          # clean aux files
```

## Core Syntax Reference

### Document class & preamble
```latex
\documentclass[11pt,a4paper,twoside]{article}   % article|report|book|letter|beamer

% ---- preamble: packages & configuration ----
\usepackage[utf8]{inputenc}     % (pdfTeX; XeTeX/LuaTeX are Unicode-native)
\usepackage[T1]{fontenc}
\usepackage{amsmath,amssymb}    % math
\usepackage{graphicx}           % \includegraphics
\usepackage{hyperref}           % clickable links/refs (load LAST, mostly)
\usepackage[margin=1in]{geometry}

\title{My Paper}
\author{Author Name}
\date{\today}

\begin{document}
\maketitle
\tableofcontents
% ... body ...
\end{document}
```
Everything before `\begin{document}` is the **preamble** (packages, macro definitions, metadata). `hyperref` should generally be loaded last.

### Common document classes
- `article` — papers, short reports (no chapters)
- `report` — longer reports with chapters
- `book` — books (chapters, front/back matter, two-sided)
- `letter` — correspondence
- `beamer` — presentation slides
- `standalone` — crop output to content (great for figure export)
- Journal classes: `IEEEtran`, `revtex4-2`, `elsarticle`, `acmart`

### Sectioning & cross-references
```latex
\chapter{Title}          % book/report only
\section{Introduction}\label{sec:intro}
\subsection{Background}
\subsubsection{Detail}
\paragraph{Run-in heading.}

As discussed in Section~\ref{sec:intro} on page~\pageref{sec:intro}.
\autoref{sec:intro}      % hyperref: "Section 1"
```
Always `\label` after the thing being labeled, and reference with `\ref`/`\autoref`. Use a non-breaking `~` before `\ref` to avoid a line break.

### Math (the core strength)
```latex
Inline: $E = mc^2$ or \( a^2 + b^2 = c^2 \)

Display (unnumbered):
\[ \int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2} \]

Numbered equation:
\begin{equation}\label{eq:quad}
  x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
\end{equation}

Aligned multi-line (amsmath):
\begin{align}
  f(x) &= (x+1)^2 \\
       &= x^2 + 2x + 1
\end{align}

Matrix:
\[ \begin{bmatrix} 1 & 2 \\ 3 & 4 \end{bmatrix} \]

Cases:
\[ |x| = \begin{cases} x & x \ge 0 \\ -x & x < 0 \end{cases} \]
```
Load `amsmath` for `align`, `cases`, `\text{}`, and proper spacing. Reference equations with `\eqref{eq:quad}`.

### Environments
```latex
\begin{itemize}
  \item bullet
\end{itemize}

\begin{enumerate}
  \item numbered
\end{enumerate}

\begin{description}
  \item[Term] definition
\end{description}

\begin{quote} ... \end{quote}
\begin{verbatim} literal text, no macros \end{verbatim}
```

### Floats: figures & tables
```latex
\begin{figure}[htbp]
  \centering
  \includegraphics[width=0.8\textwidth]{diagram.png}
  \caption{System architecture.}
  \label{fig:arch}
\end{figure}

\begin{table}[htbp]
  \centering
  \caption{Results.}
  \label{tab:results}
  \begin{tabular}{lcr}
    \toprule
    Name & Count & Price \\
    \midrule
    Widget & 5 & 9.99 \\
    Gadget & 3 & 19.99 \\
    \bottomrule
  \end{tabular}
\end{table}
```
Placement `[htbp]` = here/top/bottom/page. Use `booktabs` (`\toprule`/`\midrule`/`\bottomrule`) for professional tables — never vertical rules.

### Bibliography
```latex
% BibLaTeX (modern, recommended)
\usepackage[style=numeric,backend=biber]{biblatex}
\addbibresource{refs.bib}
...
Cited work~\cite{knuth1984}.
...
\printbibliography

% Legacy BibTeX alternative:
% \bibliographystyle{plain}
% \bibliography{refs}
```
BibLaTeX+biber is the current standard; run `biber` (via `latexmk`) between LaTeX passes.

### TikZ (native vector graphics & adjacency/graphs)
```latex
\usepackage{tikz}
\usetikzlibrary{arrows.meta,positioning}

\begin{tikzpicture}[node distance=2cm,>=Stealth]
  \node[circle,draw] (a) {A};
  \node[circle,draw,right=of a] (b) {B};
  \node[circle,draw,below=of a] (c) {C};
  \draw[->] (a) -- (b);
  \draw[->] (a) -- (c);
  \draw[->] (b) -- (c) node[midway,right] {edge};
\end{tikzpicture}
```
TikZ draws diagrams, graphs (adjacency via nodes+edges), plots (`pgfplots`), and commutative diagrams directly in the document — no external image needed.

## How-To (worked recipes)

### How to add colors & styling
Use the `xcolor` package for text/background color and `\definecolor` for a custom palette:
```latex
\usepackage{xcolor}
\definecolor{brandblue}{HTML}{1E6FBA}
\definecolor{softbg}{RGB}{245,247,250}

{\color{brandblue} colored text}
\textcolor{red}{error}
\colorbox{softbg}{highlighted box}
\fcolorbox{brandblue}{softbg}{framed \& filled}
```
For colored section headings, combine with `titlesec`:
```latex
\usepackage{titlesec}
\titleformat{\section}{\Large\bfseries\color{brandblue}}{\thesection}{1em}{}
```
`xcolor` accepts `HTML`, `RGB` (0–255), `rgb` (0–1), and named models — the canonical "add colors" mechanism in LaTeX.

### How to typeset source code (minted or listings)
```latex
% Option A: listings (pure TeX, no external tools)
\usepackage{listings}
\lstset{basicstyle=\ttfamily\small,keywordstyle=\color{blue},
        commentstyle=\color{gray},frame=single,breaklines=true}
\begin{lstlisting}[language=Python]
def greet(name):
    return f"Hi {name}"
\end{lstlisting}

% Option B: minted (Pygments highlighting; compile with -shell-escape)
\usepackage{minted}
\begin{minted}{python}
def greet(name):
    return f"Hi {name}"
\end{minted}
```
`minted` produces the best highlighting but requires Python/Pygments and `latexmk -shell-escape`. `listings` needs no external dependency.

### How to include and reference figures/tables
```latex
See Figure~\ref{fig:arch} and Table~\ref{tab:results}.
```
`\ref` resolves the `\label` inside the float; LaTeX numbers floats automatically. Run the build twice so references resolve (or use `latexmk`, which reruns as needed).

### How to support multiple languages (babel / polyglossia)
```latex
% pdfTeX
\usepackage[english,french]{babel}
% XeTeX/LuaTeX (better Unicode/font support)
\usepackage{polyglossia}
\setmainlanguage{english}
\setotherlanguage{arabic}
```
`babel` handles hyphenation, date formats, and quotation conventions per language. For non-Latin scripts, prefer XeTeX/LuaTeX + `fontspec` + `polyglossia`.

## Do's and Don'ts

### ✅ Do
- Use **`latexmk`** — it runs pdfLaTeX/biber the correct number of times automatically.
- Load **`hyperref` last** (with a few documented exceptions like `cleveref` after it).
- Use **`booktabs`** rules for tables; avoid vertical lines and `\hline` clutter.
- Use **semantic macros** (`\newcommand{\vect}[1]{\mathbf{#1}}`) instead of repeating formatting.
- Prefer **XeTeX/LuaTeX + `fontspec`** when you need system fonts or full Unicode.
- Always `\label` immediately after `\caption` inside floats (order matters).

### ❌ Don't
- Don't put a `\label` before its `\caption` — the reference number will be wrong.
- Don't use `$$...$$` for display math — it's plain TeX and breaks `amsmath` spacing; use `\[...\]` or `equation`.
- Don't hardcode manual figure/section numbers — let LaTeX number and `\ref` them.
- Don't fight float placement with `[H]` everywhere (needs `float` pkg); trust `[htbp]` and reorder text instead.
- Don't forget `-shell-escape` when using `minted`, or the build fails.
- Don't mix `inputenc` with XeTeX/LuaTeX — those engines are natively UTF-8.

## Styling, Theming & Customization
- **Fonts**: pdfTeX uses `\usepackage{lmodern}`, `mathpazo`, etc.; XeTeX/LuaTeX use `\setmainfont{...}` via `fontspec`.
- **Page geometry**: `geometry` package (`\usepackage[margin=1in]{geometry}`).
- **Headers/footers**: `fancyhdr` (`\pagestyle{fancy}`, `\fancyhead[L]{...}`).
- **Section formatting**: `titlesec`; TOC formatting: `tocloft`.
- **Colors**: `xcolor` (see How-To). **Links**: `hyperref` (`\hypersetup{colorlinks=true,linkcolor=brandblue}`).
- **Beamer themes**: `\usetheme{Madrid}`, `\usecolortheme{...}` for slides.

## Advanced Features
- **`pgfplots`** — publication-quality plots from data/functions, built on TikZ.
- **`tikz-cd`** — commutative diagrams; **`forest`** — trees; **`chemfig`** — chemistry.
- **`\newcommand` / `\newenvironment`** — define reusable macros and environments.
- **`subfiles` / `\include` / `\input`** — split large documents into files.
- **`cleveref`** — smart references (`\cref{fig:arch}` → "Figure 3"); load after `hyperref`.
- **`glossaries`** — acronyms and glossary management.
- **LuaTeX** — embed Lua for programmatic typesetting.

## Common Pitfalls & Troubleshooting
- **References show `??`** → run LaTeX again (labels resolve on a second pass); use `latexmk`.
- **`Undefined control sequence`** → missing `\usepackage`, or a typo in a macro name.
- **`minted` errors** → forgot `-shell-escape` or Pygments not installed.
- **Wrong caption number** → `\label` placed before `\caption`.
- **Overfull/underfull hbox** → line-breaking warnings; add `\usepackage{microtype}`, hyphenation hints, or reword.
- **Unicode char errors (pdfTeX)** → switch to XeTeX/LuaTeX or add the right `inputenc`.
- **Float "stuck at end"** → too many unplaced floats; add `\clearpage` or relax placement.

## Integration Notes
- **Pandoc** converts Markdown/RST → LaTeX/PDF using a LaTeX engine under the hood (see pandoc.md).
- **Overleaf** is the dominant collaborative browser IDE.
- **Matplotlib/TikZ export**: `matplotlib` can emit PGF; `tikzplotlib` converts figures to TikZ.
- **Sphinx** and **Quarto** produce PDF via a LaTeX backend (see sphinx.md, quarto.md).

## Best For / Avoid For
`academic-papers`, `math`, `theses`, `books`, `journals`, `precise-typesetting` — choose LaTeX when mathematics, automatic numbering, bibliographies, or print-quality layout matter.
Avoid for: quick web content or READMEs (use markdown.md), rapid iteration where compile times hurt (consider typst.md — 10–100× faster), or teams unwilling to manage a TeX toolchain (typst.md, or Markdown+pandoc.md).

## See Also
- `typst.md` — modern, faster LaTeX alternative with simpler syntax
- `pandoc.md` — generate LaTeX/PDF from Markdown/RST
- `sphinx.md`, `quarto.md`, `r-markdown.md` — pipelines that emit PDF via LaTeX
- `../use-case/document-processing.md`, `../use-case/document-processing.md`
