# reveal.js - FIM Solution Documentation

## Description
[reveal.js](https://revealjs.com) is an HTML presentation framework for building browser-based slide decks with transitions, speaker notes, fragments, and PDF export. It turns Markdown or HTML into shareable, web-native talks — ideal for repurposing an article into a conference talk or embeddable deck.

## Basic Syntax
```html
<div class="reveal"><div class="slides">
  <section data-markdown>
    <textarea data-template>
      ## Rate Limiting 101
      Token buckets, leaky buckets, and sliding windows.
      ---
      ## Token Bucket
      - Allows bursts <!-- .element: class="fragment" -->
      - Refills at a fixed rate <!-- .element: class="fragment" -->
      Note: Mention monotonic clock pitfalls here.
    </textarea>
  </section>
</div></div>
<script>Reveal.initialize({ hash: true, slideNumber: true });</script>
```

## Toolchain
- **reveal.js core** - Framework + themes + transitions
- **reveal-md** - Render a single Markdown file to a deck (CLI/server)
- **decktape** - Export any reveal deck to PDF
- **plugins** - Highlight (code), Math (KaTeX), Notes (speaker view), Search
- **Quarto** - `format: revealjs` for scientific decks from `.qmd`

## Strengths
- Pure web output — shareable via URL, embeddable in articles
- Markdown authoring with `reveal-md` for fast decks
- Speaker notes, fragments, vertical slides, and auto-animate
- Code highlighting + math via official plugins
- PDF export through decktape or print stylesheet

## Limitations
- Custom layouts require HTML/CSS knowledge
- Large media decks can get heavy in the browser
- PDF export needs a headless browser (decktape/Chrome)
- Less "drag-and-drop" than PowerPoint/Keynote for designers

## Best Use Cases
- Repurposing a blog article into a conference/meetup talk
- Embeddable, linkable decks inside documentation or newsletters
- Developer talks needing live code highlighting and math
- Version-controlled, Markdown-authored presentations

## NPL-FIM Integration
```npl
⌜revealjs-deck|revealjs|FIM@1.0⌝
format: reveal.js
source: markdown (reveal-md) | html
plugins: [highlight, math-katex, notes]
export: html | pdf (decktape)
⌞revealjs-deck⌟
```

NPL agents generate reveal.js decks (usually from Markdown via reveal-md) when an article is repurposed into a web-native, linkable presentation.
