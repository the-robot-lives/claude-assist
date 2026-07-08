# Markdown

## What
Markdown is a lightweight markup language for creating formatted text in plain-text editors, emphasizing readability of the source itself. Variants include GitHub Flavored Markdown (GFM), MDX, CommonMark, and MultiMarkdown.

## How
- The LLM emits Markdown text: `#` headings, `**bold**`/`*italic*`, lists, `[links]()`, `![images]()`, blockquotes, and fenced code blocks.
- Rendered by parsers/processors such as marked.js, markdown-it, Remark (AST manipulation), or Pandoc; converts readily to HTML, PDF, or DOCX.
- Final artifact: HTML (most commonly), or PDF/DOCX/AST via converters.

## Why
- Reach for Markdown as the default for README files, wikis, technical blogs, and as the content format feeding static site generators (Jekyll, Hugo, Gatsby) — minimal learning curve, version-control friendly, ubiquitous ecosystem support.
- Tradeoffs: limited table formatting, no native footnotes without extensions, complex layouts require HTML fallback, and parsing is inconsistent across implementations without CommonMark.
- It is the lightweight baseline of this category: reach for AsciiDoc/reStructuredText when you outgrow its structural limits, and it is the content layer under most SSGs.

## Source
- Solution reference: `fim/solution/markdown.md`
