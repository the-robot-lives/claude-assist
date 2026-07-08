# MathJax — Full-Featured Math Typesetting for the Web

MathJax renders LaTeX, MathML, and AsciiMath into high-quality math on web pages, outputting
either SVG or CHTML (styled HTML+CSS). It is the most *complete* browser math renderer:
broad LaTeX coverage, extension packages, accessibility (MathML + screen-reader explorer),
and dynamic re-typesetting. It is heavier and slower than KaTeX — choose MathJax when you
need coverage, MathML, accessibility, or AsciiMath; choose KaTeX for raw speed on common LaTeX.

**Current Version**: MathJax 3.2.x (v4 in progress)  **License**: Apache-2.0
**Bundle**: ~1MB+ (component-dependent)  **Runtime**: Browser (SVG/CHTML output); Node for server-side pre-render

## Official Resources & Documentation
- Site & docs: https://www.mathjax.org/ , https://docs.mathjax.org/
- Config reference: https://docs.mathjax.org/en/latest/options/index.html
- TeX extension list: https://docs.mathjax.org/en/latest/input/tex/extensions.html
- GitHub: https://github.com/mathjax/MathJax
- npm: https://www.npmjs.com/package/mathjax

## Installation & Setup

### CDN (configure BEFORE loading the script)
```html
<script>
  window.MathJax = {
    tex: {
      inlineMath: [['$', '$'], ['\\(', '\\)']],
      displayMath: [['$$', '$$'], ['\\[', '\\]']],
      processEscapes: true,
      packages: { '[+]': ['ams', 'color', 'physics'] },
    },
    svg: { fontCache: 'global' },   // or use output: 'chtml'
  };
</script>
<script id="MathJax-script" async
  src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
```
Component bundles: `tex-mml-chtml` (TeX+MathML→CHTML), `tex-svg` (TeX→SVG),
`tex-chtml`, `mml-chtml`. Pick the smallest that covers your inputs/output.

### npm (bundler / SSR)
```bash
npm install mathjax
```

## Core API Reference

MathJax scans the page (or a subtree) for delimited math and replaces it with rendered
output. In v3 the runtime lives under `MathJax.*` once startup completes.

### Delimiters & static content
```html
<p>Inline: $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$</p>
<p>Display: $$\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}$$</p>
<p>MathML also works if input includes the mml component.</p>
```

### Dynamic typesetting (after DOM changes)
```javascript
// Re-typeset only the nodes you changed (best perf):
await MathJax.typesetPromise([document.getElementById('math-content')]);

// Whole document:
await MathJax.typesetPromise();

// Clear previous output before re-typesetting the same nodes:
MathJax.typesetClear([element]);
```

### Convert a string directly (no DOM scan)
```javascript
// TeX → SVG element (requires the tex-svg or *-svg component):
const node = MathJax.tex2svg('\\int_0^\\infty e^{-x}\\,dx = 1', { display: true });
document.body.appendChild(node);

// TeX → CHTML:
const chtml = MathJax.tex2chtml('E = mc^2', { display: false });

// MathML → CHTML/SVG:
const out = MathJax.mathml2chtml('<math><mi>x</mi></math>');
```
After `tex2chtml`/`tex2svg`, call `MathJax.startup.document.updateDocument()` to insert
required stylesheet/font references once.

### Startup hooks & config at runtime
```javascript
MathJax.startup.promise.then(() => console.log('MathJax ready'));
MathJax.config.tex.macros = { RR: '\\mathbb{R}' };   // adjust before typeset
```

## Input & Output Modes
- **Inputs**: TeX/LaTeX (`input/tex`), MathML (`input/mml`), AsciiMath (`input/asciimath`).
- **Outputs**: CHTML (HTML+CSS, selectable text, default), SVG (self-contained, best for export/print).
- **Extensions**: `ams`, `color`, `physics`, `mhchem` (chemistry), `cancel`, `bbox`, `boldsymbol`,
  `braket`, `newcommand`, `unicode`, `autoload`.

## How-To (worked recipes)

### How to add color and styling to equations
Enable the `color` package (or use `\style`/`\class`), then color inside LaTeX.
```html
<script>
  window.MathJax = { tex: { packages: { '[+]': ['color'] } } };
</script>
...
<p>$\color{red}{x^2} + \color{#2980b9}{2x} - 3$</p>
<p>$$\class{highlight}{\int_0^1 x^2\,dx}$$</p>  <!-- style .highlight in CSS -->
```

### How to define reusable macros
```javascript
window.MathJax = {
  tex: {
    macros: {
      RR: '\\mathbb{R}',
      norm: ['\\left\\lVert #1 \\right\\rVert', 1],   // 1-arg macro
      dd:  '\\mathrm{d}',
    },
  },
};
// Usage: $\norm{x} \in \RR,\quad \int f\,\dd x$
```

### How to render math added after page load (SPA)
```javascript
function appendEquation(container, tex) {
  container.insertAdjacentHTML('beforeend', `<div>\\[${tex}\\]</div>`);
  return MathJax.typesetPromise([container]);  // typeset just the new subtree
}
appendEquation(document.getElementById('feed'), '\\nabla \\cdot \\mathbf{E} = \\rho/\\varepsilon_0');
```

### How to export an equation as standalone SVG
```javascript
// Load the tex-svg component, then:
const svgNode = MathJax.tex2svg('\\sqrt{a^2+b^2}', { display: true });
const svgEl = svgNode.querySelector('svg');
const serialized = new XMLSerializer().serializeToString(svgEl);   // save/download
```

### How to render aligned/multi-line equations
```html
<p>$$\begin{align}
  \nabla \cdot \mathbf{E} &= \frac{\rho}{\varepsilon_0} \\
  \nabla \cdot \mathbf{B} &= 0 \\
  \nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t}
\end{align}$$</p>
```
`align` (numbered) and `align*`/`aligned` (unnumbered) come from the `ams` package (enabled by default in the `tex-mml-chtml` bundle).

## Framework Integration

### React
```jsx
import { useEffect, useRef } from 'react';

function MathBlock({ tex }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current && window.MathJax?.typesetPromise) {
      ref.current.innerHTML = `\\[${tex}\\]`;
      window.MathJax.typesetPromise([ref.current]);
    }
  }, [tex]);
  return <div ref={ref} />;
}
```
Load MathJax once (CDN + config) at app root; each component typesets only its own subtree.

### Node / build-time SSR (mathjax-full)
```javascript
// Pre-render to SVG at build time so the browser ships no MathJax JS.
// Uses the mathjax-full package's tex → svg conversion pipeline.
```

## Do's and Don'ts

### ✅ Do
- Set `window.MathJax = {...}` *before* the script tag loads; config after load is ignored for startup.
- Use `typesetPromise([nodes])` scoped to changed elements for dynamic content — far faster than re-scanning the page.
- Enable only the TeX packages you need to keep startup light.
- Prefer SVG output for print/export fidelity; CHTML for selectable, reflowable text.
- Use `fontCache: 'global'` (SVG) to dedupe repeated glyphs across many equations.

### ❌ Don't
- Don't re-typeset the whole document on every change — scope to nodes.
- Don't forget `processEscapes: true` if you need literal `$` in text near math.
- Don't mix delimiters that collide with page content (e.g. bare `$` in prose about prices) — restrict or escape.
- Don't expect KaTeX-level speed; MathJax trades throughput for coverage/features.
- Don't call render APIs before `MathJax.startup.promise` resolves.

## Styling, Theming & Customization
- **In-math color/style**: `color` package (`\color{...}`), `\class{...}`, `\cssId{...}`, `\style{...}`.
- **Global size**: config `chtml.scale` / `svg.scale`, or CSS `font-size` on the container (math scales with surrounding text).
- **Fonts**: MathJax fonts by default; v4 adds selectable font families.
- **Line breaking**: `chtml`/`svg` `linebreaks` options for long display equations.
- **Dark mode**: CHTML inherits `color`; ensure sufficient contrast or set explicit colors.

## Advanced Features
- **Accessibility**: built-in MathML output + the *Explorer* (keyboard navigation, speech, braille) — a key reason to choose MathJax.
- **mhchem** for chemical equations; **physics** for bra-ket/derivative shortcuts.
- **AsciiMath** input for lightweight authoring.
- **Server-side rendering** via the Node API (`mathjax-full`) to pre-render SVG/CHTML at build time.
- **Custom extensions/macros** and `\require{}` autoloading.

## Common Pitfalls & Troubleshooting
- **Math not rendering** → config placed after the script tag, or wrong delimiters.
- **Dynamic content stays raw** → forgot `typesetPromise` after inserting nodes.
- **Slow page** → too many packages, or re-typesetting the whole doc; scope and trim.
- **`$` eating prose** → disable single-`$` inline math or escape with `processEscapes`.
- **Fonts missing after `tex2svg`/`tex2chtml`** → call `updateDocument()` to insert font/CSS once.

## Integration Notes
- **Markdown/docs**: pairs with static site generators (add the CDN script + config).
- **React**: typeset in an effect after render; scope to the component's ref.
- **SSR/build-time**: use `mathjax-full` in Node to emit SVG and avoid client JS entirely.
- Faster alternative for common LaTeX: [katex](katex.md).

## Best For / Avoid For
`full-latex`, `mathml`, `accessibility`, `chemistry`, `asciimath`, `print-quality`,
`dynamic-math` — choose MathJax when coverage, MathML, or accessibility matter.
Avoid for: latency-critical pages with lots of simple equations (use [katex](katex.md)),
interactive graphing ([desmos-api](desmos-api.md)/[geogebra-api](geogebra-api.md)), or 3D math ([mathbox](mathbox.md)).

## See Also
- [katex](katex.md) — faster, lighter renderer for common LaTeX
- [desmos-api](desmos-api.md) / [geogebra-api](geogebra-api.md) — interactive math, not just typesetting
- [jsxgraph](jsxgraph.md) — geometry with LaTeX labels via MathJax
- [mathbox](mathbox.md) — 3D math graphics to accompany equations
- Use case: [../use-case/mathematical-scientific.md](../use-case/mathematical-scientific.md)
