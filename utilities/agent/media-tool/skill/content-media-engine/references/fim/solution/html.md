# HTML — Standalone Page as a Generation Target

HTML5 is the universal fallback "page" format: a single, self-contained document combining semantic markup, CSS layout/theming, and JavaScript behaviour that renders in any browser with zero build step. When no more specialized solution fits — or when the deliverable is a *document*, dashboard, tutorial, or report meant to be opened directly — emit standalone HTML. This reference covers writing correct, accessible, self-contained pages that embed images, tables, and charts, and that theme cleanly in light and dark.

**Standard**: HTML Living Standard (WHATWG) + CSS/ECMAScript  **License**: open web standard  **Runtime**: every browser; no dependencies required.

## Official Resources & Documentation
- MDN HTML: https://developer.mozilla.org/en-US/docs/Web/HTML
- MDN CSS: https://developer.mozilla.org/en-US/docs/Web/CSS
- HTML spec: https://html.spec.whatwg.org/
- WCAG (accessibility): https://www.w3.org/WAI/WCAG22/quickref/

## Document Skeleton
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Report Title</title>
  <style>/* inline CSS keeps the file self-contained */</style>
</head>
<body>
  <main>
    <!-- content -->
  </main>
  <script>/* inline JS, no external requests */</script>
</body>
</html>
```
For a truly portable artifact, inline all CSS/JS and embed assets as `data:` URIs — one file, no network.

## Semantic Structure

Use elements for meaning, not appearance. This drives accessibility, SEO, and default styling.

```html
<header>      <!-- page/section masthead -->
<nav>         <!-- navigation landmarks -->
<main>        <!-- one per page: primary content -->
<article>     <!-- self-contained, syndicatable unit -->
<section>     <!-- thematic grouping, usually with a heading -->
<aside>       <!-- tangential content, sidebars -->
<figure><figcaption>  <!-- media + caption -->
<footer>      <!-- metadata, credits -->
<h1>–<h6>     <!-- one <h1>; don't skip levels -->
```

```html
<article>
  <header><h1>Quarterly Review</h1><p class="byline">Finance · 2026-07</p></header>
  <section>
    <h2>Summary</h2>
    <p>Revenue rose <strong>18%</strong> QoQ.</p>
    <figure>
      <img src="chart.png" alt="Revenue by month, trending upward from Jan to Jun">
      <figcaption>Figure 1. Monthly revenue.</figcaption>
    </figure>
  </section>
  <footer><p>Generated automatically.</p></footer>
</article>
```

## Content Elements

### Text & inline semantics
```html
<p>Paragraph with <strong>importance</strong>, <em>emphasis</em>, <code>inline code</code>,
   <mark>highlight</mark>, <abbr title="Key Performance Indicator">KPI</abbr>,
   and a <a href="https://example.com">link</a>.</p>
<blockquote cite="src">Quoted material.</blockquote>
<pre><code>preformatted
block</code></pre>
```

### Lists
```html
<ul><li>Unordered</li></ul>
<ol><li>Ordered</li></ol>
<dl><dt>Term</dt><dd>Definition</dd></dl>
```

### Tables (data, not layout)
```html
<table>
  <caption>Inventory</caption>
  <thead><tr><th scope="col">SKU</th><th scope="col">Qty</th></tr></thead>
  <tbody>
    <tr><th scope="row">A-1</th><td>3</td></tr>
    <tr><th scope="row">B-7</th><td>1</td></tr>
  </tbody>
  <tfoot><tr><th scope="row">Total</th><td>4</td></tr></tfoot>
</table>
```

### Media
```html
<img src="pic.jpg" alt="Descriptive text" loading="lazy" width="640" height="360">
<picture>
  <source srcset="hero.avif" type="image/avif">
  <source srcset="hero.webp" type="image/webp">
  <img src="hero.jpg" alt="Hero">
</picture>
<video controls width="640"><source src="clip.mp4" type="video/mp4"></video>
<audio controls src="track.mp3"></audio>
<canvas id="viz" width="600" height="300"></canvas>
<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" fill="#4ecdc4"/></svg>
```

## CSS Layout Essentials

### Flexbox (1D)
```css
.row { display: flex; gap: 1rem; align-items: center; justify-content: space-between; flex-wrap: wrap; }
.grow { flex: 1 1 auto; }
```

### Grid (2D)
```css
.cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem; }
.layout { display: grid; grid-template: "head head" auto "nav main" 1fr "foot foot" auto / 200px 1fr; }
```

### Responsive
```css
:root { --pad: clamp(1rem, 4vw, 3rem); }
.container { max-width: 72ch; margin-inline: auto; padding-inline: var(--pad); }
@media (max-width: 640px) { .row { flex-direction: column; } }
```

## How-To (worked recipes)

### How to add colours, theming, and light/dark support (the styling recipe)
```html
<style>
  :root {
    --bg: #ffffff; --fg: #1a202c; --accent: #2b6cb0; --muted: #718096; --card: #f7fafc;
  }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #0f172a; --fg: #e2e8f0; --accent: #63b3ed; --muted: #94a3b8; --card: #1e293b; }
  }
  body { background: var(--bg); color: var(--fg); font: 16px/1.6 system-ui, sans-serif; }
  a { color: var(--accent); }
  .card { background: var(--card); border-radius: 12px; padding: 1.25rem;
          box-shadow: 0 1px 3px rgba(0,0,0,.12); }
  .badge { background: var(--accent); color: #fff; padding: .15em .6em; border-radius: 999px; }
</style>
```
Drive all colour from CSS custom properties and flip them under `prefers-color-scheme: dark` so one stylesheet themes both modes.

### How to embed a self-contained chart (no external libs)
```html
<figure class="card">
  <svg viewBox="0 0 300 120" role="img" aria-label="Monthly revenue bar chart">
    <g fill="var(--accent)">
      <rect x="10"  y="60" width="40" height="60"></rect>
      <rect x="70"  y="30" width="40" height="90"></rect>
      <rect x="130" y="45" width="40" height="75"></rect>
      <rect x="190" y="20" width="40" height="100"></rect>
    </g>
  </svg>
  <figcaption>Revenue trend</figcaption>
</figure>
```
For richer charts, drop in a `<canvas>` + a charting library, or inline generated SVG (see `svg_js.md`).

### How to make a responsive card grid
```html
<style>
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 1rem; }
</style>
<section class="grid">
  <article class="card"><h3>Uptime</h3><p>99.98%</p></article>
  <article class="card"><h3>Latency</h3><p>42 ms</p></article>
  <article class="card"><h3>Errors</h3><p>0.1%</p></article>
</section>
```

### How to add lightweight interactivity without a framework
```html
<button id="toggle" aria-expanded="false" aria-controls="details">Details</button>
<div id="details" hidden><p>Expanded content.</p></div>
<script>
  const btn = document.getElementById('toggle');
  const box = document.getElementById('details');
  btn.addEventListener('click', () => {
    const open = box.hidden;
    box.hidden = !open;
    btn.setAttribute('aria-expanded', String(open));
  });
</script>
```

## Do's and Don'ts

### ✅ Do
- Set `<!DOCTYPE html>`, `lang`, `charset`, and a responsive `viewport` on every page.
- Use one `<h1>` and a logical, unskipped heading hierarchy; use landmark elements (`main`, `nav`, `header`, `footer`).
- Give every `<img>` a meaningful `alt` (empty `alt=""` for purely decorative images).
- Theme with CSS custom properties + `prefers-color-scheme` so light/dark both work from one stylesheet.
- Inline CSS/JS and embed assets as `data:` URIs when the deliverable must be a single portable file.

### ❌ Don't
- Don't use tables for layout — tables are for tabular data; use Flexbox/Grid for layout.
- Don't rely on colour alone to convey meaning (accessibility) — add text/icons/patterns.
- Don't skip heading levels (`h1` → `h3`); screen readers and outlines depend on order.
- Don't ship external `<script src>`/`<link>` in a "self-contained" artifact — a strict CSP or offline open will break it. Inline instead.
- Don't leave interactive controls unlabeled — use `aria-*`, `<label>`, and real `<button>`/`<a>` elements.

## Accessibility & SEO
```html
<meta name="description" content="One-sentence page summary.">
<html lang="en">                     <!-- language for assistive tech -->
<a class="skip" href="#main">Skip to content</a>
<img alt="...">                     <!-- non-empty for informative images -->
<button aria-label="Close">×</button>
<table><caption>...</caption><th scope="col">   <!-- table semantics -->
```
Meet contrast ratios (4.5:1 body text), support keyboard focus (`:focus-visible`), and respect `prefers-reduced-motion` for animations.

## Common Pitfalls & Troubleshooting
- *Mobile layout zoomed/broken* → missing `<meta name="viewport">`.
- *Garbled characters* → missing `<meta charset="UTF-8">`.
- *Dark mode unreadable* → hard-coded colours instead of themed custom properties.
- *Screen reader skips content* → non-semantic `<div>` soup; use landmarks and headings.
- *Artifact fails offline / under CSP* → external resource references; inline and embed as `data:` URIs.

## Best For / Avoid For
`documentation`, `reports`, `dashboards`, `landing-pages`, `tutorials`, `email-adjacent-pages`, `self-contained-artifacts` — the default when the output is a viewable page and no specialized renderer is required.
Avoid for: print-exact pagination (use `pdfkit`/`jspdf`), heavy real-time graphics (canvas/WebGL), or data interchange (use JSON/`sheetjs`).

## See Also
- `canvas-api.md` / `svg_js.md` — embed raster or vector graphics into the page
- `sheetjs.md` (`sheet_to_html`) / `mammoth_js.md` (DOCX→HTML) — sources that produce HTML
- `pdfkit.md` / `jspdf.md` — when the page must become a fixed-layout PDF
- `../use-case/document-generation.md`
