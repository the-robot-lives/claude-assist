# Desmos API — Embeddable Graphing Calculator

The Desmos API embeds the Desmos graphing calculator (and its scientific, four-function,
and geometry variants) into a web page. You drive it programmatically: add LaTeX
expressions, sliders, points, and tables; read computed values; observe changes; and export
screenshots or serialized state. It is a math/interactive-graphing tool (with audio-adjacent
uses like plotting waveforms) rather than a plotting *library* — the calculator's own engine
handles evaluation and rendering.

**Current Version**: Calculator API v1.11 (versioned URL)  **License**: Free for non-commercial/educational; commercial needs a partner API key
**Runtime**: Embedded calculator widget (`calculator.js`)  **Requires**: API key in the script URL

## Official Resources & Documentation
- API docs: https://www.desmos.com/api/v1.11/docs/
- API landing / key request: https://www.desmos.com/api
- Examples: https://www.desmos.com/api/v1.11/docs/index.html#document-examples
- Main calculator: https://www.desmos.com/calculator

## Installation & Setup

### Include the script + container
```html
<script src="https://www.desmos.com/api/v1.11/calculator.js?apiKey=YOUR_API_KEY"></script>
<div id="calculator" style="width: 600px; height: 400px;"></div>
```
The demo key `dcb31709b452b1cf9dc26972add0fda6` works for testing; request your own for production.

### Instantiate
```javascript
const elt = document.getElementById('calculator');
const calculator = Desmos.GraphingCalculator(elt, {
  keypad: true,
  expressions: true,
  settingsMenu: true,
  zoomButtons: true,
  expressionsTopbar: true,
  border: true,
});
```
Other constructors: `Desmos.ScientificCalculator(elt)`, `Desmos.FourFunctionCalculator(elt)`,
`Desmos.GeometryCalculator(elt)`.

## Core API Reference

Everything on the graph is an **expression** identified by a stable `id`. Expressions carry
LaTeX, and Desmos evaluates them — including implicit relationships between sliders and curves.

### setExpression — add/update anything
```javascript
calculator.setExpression({ id: 'parabola', latex: 'y=x^2+2x-3', color: Desmos.Colors.BLUE });
calculator.setExpression({ id: 'para', latex: '(t\\cos(t), t\\sin(t))', color: Desmos.Colors.RED });
calculator.setExpression({ id: 'pt', latex: 'P=(3,4)', showLabel: true, dragMode: Desmos.DragModes.XY });
calculator.setExpression({ id: 'a', latex: 'a=1', sliderBounds: { min: -5, max: 5, step: 0.1 } });
calculator.setExpression({ id: 'ineq', latex: 'y<x^2', color: '#3B5', fillOpacity: 0.4 });
```

### Tables
```javascript
calculator.setExpression({
  type: 'table',
  id: 't1',
  columns: [
    { latex: 'x', values: ['1', '2', '3', '4'] },
    { latex: 'y', values: ['1', '4', '9', '16'], color: Desmos.Colors.PURPLE, points: true, lines: true },
  ],
});
```

### Batch expressions & removal
```javascript
calculator.setExpressions([
  { id: 'f', latex: 'f(x)=\\sin(x)' },
  { id: 'g', latex: 'g(x)=\\cos(x)' },
]);
calculator.removeExpression({ id: 'g' });
calculator.setBlank();          // clear everything
```

### Viewport / math bounds
```javascript
calculator.setMathBounds({ left: -10, right: 10, bottom: -10, top: 10 });
const box = calculator.graphpaperBounds;   // read current pixel + math bounds
```

### Reading computed values (HelperExpression)
The graph does not return numeric results directly; observe a helper expression.
```javascript
const h = calculator.HelperExpression({ latex: 'f(2)' });
h.observe('numericValue', () => console.log('f(2) =', h.numericValue));
```

### State: save / restore / observe
```javascript
const state = calculator.getState();
localStorage.setItem('graph', JSON.stringify(state));
calculator.setState(JSON.parse(localStorage.getItem('graph')));

calculator.observeEvent('change', () => console.log('graph changed'));
calculator.observe('graphpaperBounds', () => console.log('panned/zoomed'));
```

### Screenshot / export
```javascript
const uri = calculator.screenshot({ width: 600, height: 400, targetPixelRatio: 2 });
document.querySelector('img#out').src = uri;

// Async, off-thread:
calculator.asyncScreenshot({ format: 'svg', width: 600, height: 400 }, (data) => {
  document.querySelector('#svg').innerHTML = data;
});
```

## Expression Types Supported
- Explicit/implicit functions (`y=…`, `x^2+y^2=1`), inequalities (shaded regions).
- Parametric `(x(t), y(t))` and polar `r=…` curves.
- Points, movable points (`dragMode`), lists, and point lists.
- Sliders (animatable parameters), regressions (`y_1 ~ a x_1 + b`), tables.
- Function definitions, piecewise `{condition: value}`, summations, integrals, derivatives.

## How-To (worked recipes)

### How to color and style graphs
Set `color` (named `Desmos.Colors.*` or `#RRGGBB`), `lineStyle`, `lineWidth`, `fillOpacity`,
`pointStyle`.
```javascript
calculator.setExpression({
  id: 'c1', latex: 'y=\\sin(x)',
  color: '#C0392B', lineStyle: Desmos.Styles.DASHED, lineWidth: 3,
});
calculator.setExpression({
  id: 'p1', latex: 'A=(2,3)', color: Desmos.Colors.GREEN,
  pointStyle: Desmos.Styles.OPEN, pointSize: 12,
});
```

### How to animate a slider-controlled family of curves
```javascript
calculator.setExpression({ id: 'a', latex: 'a=1', sliderBounds: { min: -3, max: 3, step: 0.05 } });
calculator.setExpression({ id: 'fam', latex: 'y=a\\cdot x^2', color: Desmos.Colors.BLUE });
// Start the built-in animation on the slider:
calculator.setExpression({ id: 'a', latex: 'a=1', playing: true });
```

### How to compute values and react to them
```javascript
calculator.setExpression({ id: 'f', latex: 'f(x)=x^2-4' });
const root = calculator.HelperExpression({ latex: 'f(3)' });
root.observe('numericValue', () => console.log('f(3)=', root.numericValue)); // 5
```

### How to export a graph as an image
```javascript
const dataUri = calculator.screenshot({ width: 800, height: 500, targetPixelRatio: 2 });
const a = document.createElement('a');
a.href = dataUri; a.download = 'graph.png'; a.click();
```

## Do's and Don'ts

### ✅ Do
- Give every expression a stable `id` so you can update it in place (re-`setExpression` with the same id).
- Escape LaTeX backslashes in JS strings (`'\\sin(x)'`, `'\\frac{1}{2}'`).
- Read numeric results via `HelperExpression().observe('numericValue', …)`, not by parsing.
- Persist/restore with `getState`/`setState` (opaque but stable across API versions).
- Request a production API key; the public demo key is for prototyping only.

### ❌ Don't
- Don't expect `setExpression` to return a computed number — it defines graph state, not results.
- Don't forget units in `setMathBounds` are *math* coordinates, not pixels.
- Don't mutate `getState` output and assume forward/backward compatibility across major versions — treat it as opaque.
- Don't animate huge families of expressions — performance degrades; use one slider-driven curve.
- Don't ship without a valid `apiKey` in the script URL — the widget won't load.

## Styling, Theming & Customization
- **Per-expression**: `color`, `lineStyle` (SOLID/DASHED/DOTTED), `lineWidth`, `pointStyle`, `pointSize`, `fillOpacity`, `hidden`, `label`.
- **Calculator chrome**: constructor options (`keypad`, `expressions`, `settingsMenu`, `zoomButtons`, `border`, `expressionsCollapsed`).
- **Axes/grid**: `calculator.updateSettings({ xAxisLabel, yAxisLabel, showGrid, showXAxis, polarMode, degreeMode })`.
- **Colors palette**: `Desmos.Colors.RED/BLUE/GREEN/PURPLE/ORANGE/BLACK` or any hex.

## Advanced Features
- **`updateSettings`**: toggle polar mode, degree/radian, projector mode, restrict panning.
- **Regressions**: fit models with `~` (`y_1 ~ a*x_1^2 + b`) and read fitted parameters via helpers.
- **Actions/tickers** (in-graph interactivity) and `Desmos.GeometryCalculator` for constructions.
- **`asyncScreenshot`** to SVG/PNG off the main thread for exports.
- **Focus/observe** APIs for tight UI integration.

## Common Pitfalls & Troubleshooting
- **Widget blank** → missing/invalid `apiKey`, or container has zero size.
- **LaTeX ignored** → unescaped backslashes or invalid LaTeX; check `expressionAnalysis`.
- **Can't get a number** → you need a `HelperExpression`; the calculator is state-in, render-out.
- **Slider won't animate** → set `playing: true` on the slider expression.
- **Screenshot blurry** → raise `targetPixelRatio`.

## Framework Integration

### React wrapper
```jsx
import { useEffect, useRef } from 'react';

function DesmosGraph({ expressions = [], bounds }) {
  const elRef = useRef(null);
  const calcRef = useRef(null);
  useEffect(() => {
    calcRef.current = window.Desmos.GraphingCalculator(elRef.current, { expressions: true });
    return () => calcRef.current?.destroy();      // always destroy to free the widget
  }, []);
  useEffect(() => {
    const c = calcRef.current; if (!c) return;
    if (bounds) c.setMathBounds(bounds);
    expressions.forEach(e => c.setExpression(e)); // stable ids → in-place updates
  }, [expressions, bounds]);
  return <div ref={elRef} style={{ width: '100%', height: 400 }} />;
}
```
Load `calculator.js?apiKey=…` once in `index.html`; `destroy()` on unmount prevents leaks.

### How to plot an audio waveform (audio-adjacent use)
```javascript
// Feed sampled amplitudes into a table to visualize a signal.
const samples = Array.from({ length: 64 }, (_, i) => Math.sin(i / 4));
calculator.setExpression({
  type: 'table',
  id: 'wave',
  columns: [
    { latex: 'x', values: samples.map((_, i) => String(i)) },
    { latex: 'y', values: samples.map(String), lines: true, points: false, color: Desmos.Colors.BLUE },
  ],
});
```

## Integration Notes
- **React**: create the calculator in a ref/effect after mount; call `calculator.destroy()` on unmount.
- **Audio-adjacent**: plot waveforms/spectra by feeding sampled data into a `table` expression.
- Pairs with [katex](katex.md)/[mathjax](mathjax.md) for typeset math *around* the interactive graph.

## Best For / Avoid For
`interactive-graphing`, `math-education`, `sliders`, `function-exploration`, `embeds`,
`quick-plots` — choose Desmos when you want a turnkey, student-friendly interactive calculator.
Avoid for: publication charts (use a dataviz lib), 3D math ([mathbox](mathbox.md)/[geogebra-api](geogebra-api.md) 3D),
geometry constructions ([jsxgraph](jsxgraph.md)/[geogebra-api](geogebra-api.md)), or offline/no-key contexts.

## See Also
- [geogebra-api](geogebra-api.md) — richer geometry/CAS/3D alternative
- [jsxgraph](jsxgraph.md) — open-source interactive geometry/plotting
- [mathbox](mathbox.md) — 3D mathematical visualization
- [katex](katex.md) / [mathjax](mathjax.md) — typeset the equations around the graph
- Use case: [../use-case/mathematical-scientific.md](../use-case/mathematical-scientific.md)
