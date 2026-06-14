# Slidev - FIM Solution Documentation

## Description
[Slidev](https://sli.dev) is a developer-focused presentation tool: Markdown-driven slides with embedded Vue components, live coding, Monaco editors, code highlighting with line focus, and export to PDF/PNG/SPA. It is the richest Markdown-based deck option for technical talks.

## Basic Syntax
```markdown
---
theme: seriph
title: Rate Limiting 101
---

# Rate Limiting 101
Token buckets, leaky buckets, sliding windows

---

## Token Bucket

```ts {2-3|5}
const bucket = { tokens: 10, rate: 2 }
function refill(now: number) {
  bucket.tokens += elapsed(now) * bucket.rate
}
```

<Tweet id="..." />  <!-- Vue components work inline -->
```

## Toolchain
- **@slidev/cli** - `slidev` dev server, `slidev export` to PDF/PNG
- **Themes** - Installable npm theme packages (`seriph`, `default`, ...)
- **Vue + UnoCSS** - Components and atomic styling inside slides
- **Monaco / Shiki** - Live editors and high-fidelity code highlighting
- **Recording** - Built-in camera + presenter mode with drawings

## Strengths
- Best-in-class code presentation (line highlighting, focus, diffs)
- Embed live Vue components, iframes, and interactive demos
- Markdown source with frontmatter per-slide configuration
- Export to PDF, PNG, or host as a static SPA
- Presenter mode, drawing/annotation, and webcam overlay

## Limitations
- Node/Vite toolchain required (heavier than Marp)
- Vue/UnoCSS knowledge needed for advanced customization
- Overkill for simple, text-only decks
- PDF export needs Playwright/Chromium

## Best Use Cases
- Developer conference talks with heavy live-code segments
- Decks embedding interactive components or demos
- Technical content where code highlighting fidelity matters
- Hosted, linkable SPA presentations from a Git repo

## NPL-FIM Integration
```npl
⌜slidev-deck|slidev|FIM@1.0⌝
format: slidev-markdown
runtime: vue + vite
features: [shiki-highlight, monaco, vue-components]
export: spa | pdf | png
⌞slidev-deck⌟
```

NPL agents choose Slidev for technical decks needing live code, component embeds, and high-fidelity syntax highlighting.
