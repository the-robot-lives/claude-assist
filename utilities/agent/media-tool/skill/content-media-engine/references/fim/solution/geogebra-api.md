# GeoGebra API — Interactive Math (Geometry, Algebra, CAS, 3D)

GeoGebra embeds a full dynamic-mathematics application into a web page: interactive geometry,
graphing, computer algebra (CAS), spreadsheets, probability, and 3D — all driven by a command
language and a JavaScript API. You inject an applet, then issue GeoGebra commands
(`evalCommand`) to construct objects and read/set their properties. Choose it when you need
*mathematical constructions and relationships* (not just plotting) with rich interactivity.

**Current Version**: GeoGebra Math Apps (deployggb, current)  **License**: Free for non-commercial use; commercial license required otherwise
**Runtime**: Embedded applet via `deployggb.js`  **Apps**: `graphing`, `geometry`, `3d`, `cas`, `classic`, `suite`

## Official Resources & Documentation
- API reference: https://wiki.geogebra.org/en/Reference:GeoGebra_Apps_API
- Commands reference: https://wiki.geogebra.org/en/Manual:Commands
- Embedding guide: https://wiki.geogebra.org/en/Reference:GeoGebra_App_Parameters
- Site: https://www.geogebra.org/

## Installation & Setup

### Embed with deployggb
```html
<script src="https://www.geogebra.org/apps/deployggb.js"></script>
<div id="ggb-applet"></div>
<script>
  const params = {
    appName: 'graphing',      // graphing | geometry | 3d | cas | classic | suite
    width: 800, height: 600,
    showToolBar: true,
    showAlgebraInput: true,
    showMenuBar: false,
    appletOnLoad: (api) => { window.ggb = api; init(); },
  };
  new GGBApplet(params, true).inject('ggb-applet');
</script>
```
`appletOnLoad` fires when the API is ready — do all scripting from there or later.

## Core API Reference

The API is a JavaScript object (`ggbApplet` / the `api` passed to `appletOnLoad`). You mostly
**`evalCommand`** GeoGebra syntax to create objects, then use typed getters/setters.

### Creating objects (GeoGebra command language)
```javascript
api.evalCommand('A = (1, 2)');
api.evalCommand('B = (4, 5)');
api.evalCommand('line = Line(A, B)');
api.evalCommand('f(x) = x^2 - 3x + 2');
api.evalCommand('c = Circle(A, 3)');
api.evalCommand('poly = Polygon(A, B, (2,0))');
```
Multiple commands: `evalCommandGetLabels` returns created object names; `evalCommandCAS` runs CAS input.

### Properties: set
```javascript
api.setColor('A', 255, 0, 0);           // RGB
api.setPointSize('A', 5);
api.setLineStyle('line', 2);            // 0 solid, 1 dashed-long, 2 dashed-short, …
api.setLineThickness('line', 4);
api.setCaption('A', 'Start');
api.setLabelVisible('A', true);
api.setVisible('c', true);
api.setFixed('A', false, true);         // (fixed, selectionAllowed)
```

### Properties: get
```javascript
const x = api.getXcoord('A');           // 1
const y = api.getYcoord('A');
const v = api.getValue('f(2)');         // evaluate
const def = api.getDefinitionString('line');
const val = api.getValueString('f');    // "f(x) = x^2 - 3x + 2"
const exists = api.exists('A');
const objects = api.getAllObjectNames(); // array
```

### Updating objects
```javascript
api.setCoords('A', 3, 1);               // move point A
api.setValue('a', 2);                   // set a numeric/slider value
api.deleteObject('c');
api.renameObject('c', 'circle1');
```

### Event listeners
```javascript
api.registerObjectUpdateListener('A', () => console.log('A moved to', api.getXcoord('A')));
api.registerAddListener((name) => console.log('added', name));
api.registerRemoveListener((name) => console.log('removed', name));
api.registerClickListener((name) => console.log('clicked', name));
```

### State: XML / base64 / files
```javascript
const xml = api.getXML();               // full construction as XML
api.setXML(xml);
const ggb64 = api.getBase64();          // whole .ggb file, base64
api.setBase64(ggb64);
```

## Supported Apps & Object Domains
- **graphing** — functions, curves, sliders, points.
- **geometry** — Euclidean constructions (lines, circles, intersections, transformations).
- **cas** — symbolic algebra (solve, factor, differentiate, integrate).
- **3d** — points, planes, surfaces, solids, parametric 3D curves.
- **suite/classic** — combined graphing + geometry + CAS + spreadsheet + probability.

## How-To (worked recipes)

### How to color and style objects
Use `setColor` (RGB), `setLineStyle`/`setLineThickness`, `setPointSize`, `setFilling`.
```javascript
api.evalCommand('c = Circle((0,0), 2)');
api.setColor('c', 41, 128, 185);   // blue
api.setFilling('c', 0.25);         // 25% fill opacity
api.setLineThickness('c', 3);
api.evalCommand('A = (1,1)');
api.setColor('A', 192, 57, 43);    // red point
api.setPointSize('A', 6);
```

### How to build a slider-controlled parabola
```javascript
api.evalCommand('a = Slider(-5, 5, 0.1)');
api.evalCommand('b = Slider(-5, 5, 0.1)');
api.evalCommand('c = Slider(-5, 5, 0.1)');
api.evalCommand('f(x) = a x^2 + b x + c');
api.evalCommand('roots = Intersect(f, xAxis)');   // dynamic roots
```

### How to construct a tangent line at a movable point
```javascript
api.evalCommand('f(x) = sin(x)');
api.evalCommand('P = Point(f)');          // constrained to the curve
api.evalCommand('t = Tangent(P, f)');
api.setColor('t', 0, 150, 0);
```

### How to work in 3D
```javascript
new GGBApplet({ appName: '3d', appletOnLoad: (api) => {
  api.evalCommand('A = (1, 2, 3)');
  api.evalCommand('S = Sphere(A, 2)');
  api.evalCommand('P: x + y + z = 6');
  api.evalCommand('curve = Curve(cos(t), sin(t), t, t, 0, 4*pi)');
  api.setColor('S', 100, 100, 255);
}}, true).inject('ggb-applet');
```

## Do's and Don'ts

### ✅ Do
- Do all scripting from `appletOnLoad` (or after) — the API doesn't exist before it fires.
- Build with `evalCommand` using GeoGebra syntax; it captures dynamic dependencies automatically.
- Use typed getters (`getValue`, `getXcoord`) for numbers; `getValueString` for display strings.
- Persist constructions with `getBase64`/`getXML` and restore with the matching setter.
- Choose the smallest `appName` that fits (e.g. `graphing`) for faster load.

### ❌ Don't
- Don't call API methods before `appletOnLoad` — they'll be undefined.
- Don't fight the dependency graph by manually re-setting derived objects; change the inputs and let GeoGebra recompute.
- Don't assume it's free for commercial embedding — GeoGebra requires a license for commercial use.
- Don't escape LaTeX here — this is GeoGebra command syntax, not LaTeX (`x^2`, `sqrt(x)`, `pi`).
- Don't load the heavy `classic`/`suite` app if `graphing` covers your needs (bundle/perf).

## Styling, Theming & Customization
- **Objects**: `setColor(name,r,g,b)`, `setLineStyle`, `setLineThickness`, `setPointSize`, `setPointStyle`, `setFilling(name, opacity)`.
- **Labels/captions**: `setLabelVisible`, `setLabelStyle`, `setCaption`.
- **View**: `setCoordSystem(xmin, xmax, ymin, ymax)` (2D), `setPerspective('G'/'3D'/…)`, `setAxesVisible`, `setGridVisible`.
- **Applet chrome**: parameters `showToolBar`, `showAlgebraInput`, `showMenuBar`, `showResetIcon`, `enableRightClick`, `borderColor`.

## Advanced Features
- **CAS**: `evalCommandCAS('Solve(x^2-4=0, x)')` for symbolic results.
- **Scripting inside GeoGebra**: attach GGBScript/JS to objects for on-click/on-update behavior.
- **Animation**: `setAnimating('a', true); startAnimation();` animates sliders/points.
- **Export**: `getPNGBase64(scale, transparent, dpi)`, `exportSVG(callback)`, `getGraphicsOptions`.
- **Multiple applets/views** and material embedding by GeoGebra `material_id`.

## Common Pitfalls & Troubleshooting
- **`api` undefined** → scripting ran before `appletOnLoad`.
- **Object not created** → command syntax error; check names and GeoGebra command spelling.
- **Nothing visible** → object outside the coordinate window; `setCoordSystem` to frame it.
- **3D commands fail** → wrong `appName`; use `'3d'` (or `setPerspective('3D')` in classic/suite).
- **Slow first load** → large app; prefer a lighter `appName` and lazy-inject.

## Framework Integration

### React wrapper
```jsx
import { useEffect, useRef } from 'react';

function GeoGebra({ commands = [], appName = 'graphing' }) {
  const hostRef = useRef(null);
  const apiRef = useRef(null);
  useEffect(() => {
    const id = 'ggb-' + Math.random().toString(36).slice(2);
    hostRef.current.id = id;
    const applet = new window.GGBApplet({
      appName, width: 800, height: 500,
      appletOnLoad: (api) => {
        apiRef.current = api;
        commands.forEach(cmd => api.evalCommand(cmd));
      },
    }, true);
    applet.inject(id);
    return () => { apiRef.current = null; if (hostRef.current) hostRef.current.innerHTML = ''; };
  }, [appName]);
  return <div ref={hostRef} />;
}
```
Load `deployggb.js` once at app root; all scripting must wait for `appletOnLoad`.

### How to embed a published GeoGebra material
Instead of scripting a construction, load one by its material id from geogebra.org.
```javascript
new GGBApplet({ material_id: 'RUEQf6zw', width: 800, height: 500 }, true).inject('ggb-applet');
```

## Integration Notes
- **React/Vue**: inject in a mount hook; grab the `api` in `appletOnLoad`; remove the applet on unmount.
- **Load saved materials** by `material_id` param instead of scripting from scratch.
- Pair with [katex](katex.md)/[mathjax](mathjax.md) for typeset prose and [desmos-api](desmos-api.md) as a lighter graphing-only alternative.

## Best For / Avoid For
`interactive-geometry`, `math-education`, `cas`, `3d-math`, `constructions`, `dynamic-math` —
choose GeoGebra when relationships/constructions and multiple math domains matter.
Avoid for: lightweight function plotting only (use [desmos-api](desmos-api.md)/[jsxgraph](jsxgraph.md)),
pure 3D graphics/animation ([mathbox](mathbox.md)), or commercial use without a license.

## See Also
- [desmos-api](desmos-api.md) — simpler graphing-calculator embed
- [jsxgraph](jsxgraph.md) — open-source interactive geometry/plotting
- [mathbox](mathbox.md) — 3D mathematical visualization
- [katex](katex.md) / [mathjax](mathjax.md) — typeset the surrounding math
- Use case: [../use-case/mathematical-scientific.md](../use-case/mathematical-scientific.md)
