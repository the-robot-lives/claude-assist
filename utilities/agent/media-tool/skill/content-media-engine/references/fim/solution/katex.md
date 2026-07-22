# KaTeX — Fast LaTeX Math Rendering for the Web

KaTeX is a fast, dependency-free LaTeX math renderer from Khan Academy. It renders
synchronously (no reflow flash), supports server-side rendering, and produces HTML+CSS (with
optional MathML for accessibility). It covers the most-used LaTeX math subset and is far
faster and lighter than MathJax — the trade-off is narrower coverage of exotic packages.
Choose KaTeX when render speed and bundle size matter and your LaTeX is mainstream.

**Current Version**: 0.16.x  **License**: MIT
**Bundle**: ~280KB JS + CSS + fonts (gzip smaller)  **Runtime**: Browser (sync) + Node (SSR); requires its CSS + fonts

## Official Resources & Documentation
- Site & live demo: https://katex.org/
- Supported functions: https://katex.org/docs/supported.html
- Support table (what's/what's not): https://katex.org/docs/support_table.html
- API/options: https://katex.org/docs/options.html
- GitHub: https://github.com/KaTeX/KaTeX
- npm: https://www.npmjs.com/package/katex

## Installation & Setup

### CDN (CSS is mandatory)
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
<!-- optional: scan the page for delimited math -->
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"></script>
```
The CSS and its bundled fonts are required — without them glyphs are misplaced/unstyled.

### Package manager
```bash
npm install katex
```
```javascript
import katex from 'katex';
import 'katex/dist/katex.min.css';
```

## Core API Reference

KaTeX has a tiny surface: render a string into an element, render to an HTML string, or use
the auto-render extension to convert delimited math in the DOM. Rendering is **synchronous**.

### render — into a DOM element
```javascript
katex.render('c = \\pm\\sqrt{a^2 + b^2}', document.getElementById('eq'), {
  displayMode: true,       // block (centered) vs inline
  throwOnError: false,     // render an error node instead of throwing
  errorColor: '#cc0000',
});
```

### renderToString — for SSR / templates
```javascript
const html = katex.renderToString('E = mc^2', { displayMode: false });
element.innerHTML = html;   // string can be generated server-side too
```

### Options object (full)
```javascript
{
  displayMode: false,      // true = display/block math
  throwOnError: true,      // false → show errorColor'd source instead of throwing
  errorColor: '#cc0000',
  macros: { '\\RR': '\\mathbb{R}' },
  colorIsTextColor: false,
  strict: 'warn',          // 'error' | 'warn' | 'ignore' | function
  trust: false,            // allow \href, \url, \includegraphics, etc. (security-sensitive)
  output: 'htmlAndMathml', // 'html' | 'mathml' | 'htmlAndMathml'
  maxSize: Infinity, maxExpand: 1000,
  fleqn: false,            // left-align display math
}
```

### Auto-render extension
Scans a container and renders delimited math in place.
```javascript
document.addEventListener('DOMContentLoaded', () => {
  renderMathInElement(document.body, {
    delimiters: [
      { left: '$$', right: '$$', display: true },
      { left: '$',  right: '$',  display: false },
      { left: '\\[', right: '\\]', display: true },
      { left: '\\(', right: '\\)', display: false },
    ],
    throwOnError: false,
    ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code'],
  });
});
```

## Coverage Overview
- **Supported**: fractions, roots, sub/superscripts, sums/integrals/limits, matrices/arrays,
  Greek, operators, delimiters, `\begin{cases}`, `align`/`aligned`, `color`, `\text`, common
  AMS symbols, accents, spacing, `\left…\right`.
- **Partial/none**: some exotic packages, arbitrary `\def` complexity, a few rarely-used
  environments — check the support table. Chemistry via the `mhchem` contrib extension.

## How-To (worked recipes)

### How to color and style math
KaTeX supports `\color`, `\textcolor`, and (with `trust`) HTML-ish styling; wrap in a styled
container for CSS control.
```javascript
katex.render('\\textcolor{#c0392b}{x^2} + \\textcolor{#2980b9}{2x} - 3', el, {
  throwOnError: false,
});
// Global sizing/color via CSS on the container:
// .eq .katex { font-size: 1.3em; color: #222; }
```

### How to define macros
```javascript
katex.render('\\RR \\ni x,\\quad \\norm{v}', el, {
  macros: {
    '\\RR': '\\mathbb{R}',
    '\\norm': '\\left\\lVert #1 \\right\\rVert',
  },
  throwOnError: false,
});
```

### How to server-side render (Node) and ship zero JS
```javascript
import katex from 'katex';
const html = katex.renderToString('\\sum_{k=0}^{n} \\binom{n}{k}', { displayMode: true });
// Emit `html` into your page + include katex.min.css. No client JS needed to display it.
```

### How to render user input safely
```javascript
function safeRender(el, input) {
  katex.render(input, el, {
    throwOnError: false,   // never break the page on bad input
    trust: false,          // block \href/\url/\includegraphics from user input
    maxExpand: 1000,       // guard against macro-expansion bombs
    strict: 'ignore',
  });
}
```

### How to render aligned multi-line equations
Use the `aligned` environment (KaTeX supports it) with `&` alignment points and `\\` breaks.
```javascript
katex.render(String.raw`\begin{aligned}
  (a+b)^2 &= a^2 + 2ab + b^2 \\
          &= a^2 + b^2 + 2ab
\end{aligned}`, el, { displayMode: true, throwOnError: false });
```

## Framework Integration

### React (inline component)
```jsx
import { useEffect, useRef } from 'react';
import katex from 'katex';
import 'katex/dist/katex.min.css';

function Math({ tex, block = false }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current) katex.render(tex, ref.current, { displayMode: block, throwOnError: false });
  }, [tex, block]);
  return <span ref={ref} />;
}
```
Or SSR: `dangerouslySetInnerHTML={{ __html: katex.renderToString(tex, { displayMode: block }) }}`.

### Markdown pipeline (build-time)
```javascript
// unified / remark
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
// .use(remarkMath).use(rehypeKatex)  →  $…$ and $$…$$ rendered at build, zero client JS
```

## Do's and Don'ts

### ✅ Do
- Always include `katex.min.css` and its fonts — layout depends on them entirely.
- Set `throwOnError: false` for any user-supplied or dynamic input so one bad expression doesn't crash rendering.
- Use `renderToString` for SSR/build-time to ship pre-rendered math with no client JS.
- Keep `trust: false` for untrusted input (prevents `\href`/`\includegraphics` injection).
- Check the support table before assuming a niche LaTeX command works.

### ❌ Don't
- Don't expect full MathJax coverage — unsupported commands error (or show source with `throwOnError:false`).
- Don't forget `output: 'htmlAndMathml'` (default) if you need screen-reader accessibility; `'html'` drops MathML.
- Don't render huge documents by re-scanning repeatedly — auto-render once, or render specific nodes.
- Don't enable `trust` globally on user content — it opens link/image injection.
- Don't ship without the fonts directory that the CSS references.

## Styling, Theming & Customization
- **In-math**: `\color{...}`, `\textcolor{...}{...}`, size commands (`\Large`, `\scriptstyle`).
- **Container CSS**: target `.katex` / `.katex-display` for `font-size`, `color`, alignment.
- **`fleqn`** option left-aligns display math; `displayMode` toggles block vs inline.
- **Fonts**: bundled KaTeX fonts (Computer Modern-like); override via CSS at your own risk (metrics are font-specific).
- **Dark mode**: `.katex { color: inherit; }` so math follows text color.

## Advanced Features
- **Synchronous rendering** — no layout-shift flash; render inside a single frame.
- **SSR** via `renderToString` (React `dangerouslySetInnerHTML`, static generators, email).
- **`mhchem`** contrib extension for chemical equations.
- **`copy-tex`** contrib: copies rendered math back as LaTeX source.
- **`strict`/`maxExpand`/`maxSize`** guards for safe rendering of untrusted input.
- **MathML output** for accessibility (`output: 'htmlAndMathml'`).

## Common Pitfalls & Troubleshooting
- **Broken layout / stacked glyphs** → CSS or fonts not loaded.
- **Blank / thrown error** → unsupported command or syntax; set `throwOnError:false` and read the red source.
- **Command "not supported"** → it's outside KaTeX's subset; use MathJax or a supported equivalent.
- **No screen-reader math** → `output` set to `'html'`; use `'htmlAndMathml'`.
- **Security concern with links/images** → `trust` enabled on untrusted input; disable it.

## Integration Notes
- **React**: `katex.renderToString` + `dangerouslySetInnerHTML`, or a wrapper like `react-katex`.
- **Markdown**: `remark-math` + `rehype-katex` render `$…$`/`$$…$$` at build time.
- **When KaTeX isn't enough**: switch to [mathjax](mathjax.md) for full LaTeX/MathML/AsciiMath.
- Pair with interactive math ([desmos-api](desmos-api.md)/[geogebra-api](geogebra-api.md)) for typeset labels/prose.

## Best For / Avoid For
`fast-math`, `ssr`, `common-latex`, `low-latency`, `lightweight`, `static-sites`,
`inline-equations` — choose KaTeX when speed/size beat exhaustive coverage.
Avoid for: exotic LaTeX packages or AsciiMath (use [mathjax](mathjax.md)), interactive
graphing ([desmos-api](desmos-api.md)/[geogebra-api](geogebra-api.md)), or 3D math ([mathbox](mathbox.md)).

## See Also
- [mathjax](mathjax.md) — fuller-coverage renderer (slower)
- [desmos-api](desmos-api.md) / [geogebra-api](geogebra-api.md) — interactive math with typeset labels
- [jsxgraph](jsxgraph.md) — geometry that can label via KaTeX
- [mathbox](mathbox.md) — 3D math graphics
- Use case: [../use-case/mathematical-scientific.md](../use-case/mathematical-scientific.md)
