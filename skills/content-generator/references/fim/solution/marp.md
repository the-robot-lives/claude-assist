# Marp - FIM Solution Documentation

## Description
[Marp](https://marp.app) (Markdown Presentation Ecosystem) turns plain Markdown into slide decks, exporting to HTML, PDF, and PPTX. With directive-based theming and a CLI, it is the lowest-friction way to convert article content into a polished deck while staying in Markdown.

## Basic Syntax
```markdown
---
marp: true
theme: gaia
paginate: true
---

# Rate Limiting 101

Token buckets, leaky buckets, sliding windows.

---

## Token Bucket

- Allows controlled bursts
- Refills at a fixed rate

![bg right:40%](diagram.png)

<!-- Speaker note: mention monotonic clock pitfalls -->
```

## Toolchain
- **@marp-team/marp-cli** - `marp slides.md -o out.pdf|pptx|html`
- **Marp for VS Code** - Live preview while authoring
- **marp-core** - Engine for custom integrations
- **Custom themes** - CSS files registered via `--theme`
- **Directives** - `theme`, `paginate`, `backgroundImage`, per-slide `<!-- _class -->`

## Strengths
- Pure Markdown source — minimal new syntax to learn
- Exports to HTML, PDF, and editable PPTX from one file
- Built-in themes plus CSS theming for brand consistency
- Image background directives for visual slides
- Git-friendly and CI-automatable via the CLI

## Limitations
- Less interactive than reveal.js (no fragments/animations by default)
- Complex custom layouts require CSS theme authoring
- PPTX export rasterizes some elements (not fully native shapes)
- PDF/PPTX export needs a Chromium runtime

## Best Use Cases
- Fast Markdown-to-deck conversion of an existing article
- Decks that must be delivered as editable PPTX
- CI pipelines that auto-build slides from repo content
- Lightweight internal talks and lightning presentations

## NPL-FIM Integration
```npl
⌜marp-deck|marp|FIM@1.0⌝
format: marp-markdown
theme: gaia | uncover | custom-css
export: html | pdf | pptx
cli: marp-cli
⌞marp-deck⌟
```

NPL agents use Marp when the goal is a quick Markdown-authored deck that may need to ship as PDF or editable PPTX.
