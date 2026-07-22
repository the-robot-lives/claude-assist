# X3DOM — declarative 3D in HTML (X3D scene graph)

X3DOM embeds the X3D scene graph directly into HTML5 as DOM elements. You write `<x3d>` markup — `<scene>`, `<shape>`, `<transform>`, `<box>`, `<material>` — and the X3DOM runtime renders it via WebGL, no plugins. Because the scene is real DOM, you manipulate it with the same tools you use for HTML: CSS-less attributes, `document.querySelector`, and standard events. It's the browser-native answer to "declarative 3D" and a bridge for CAD/VRML content.

**Current Version**: 1.8.x (npm `x3dom`, current major) **License**: MIT **Bundle/Runtime**: `x3dom.js` ~1–2 MB (full build) + `x3dom.css`; renders to a WebGL canvas injected into the `<x3d>` element.

## Official Resources & Documentation
- **Site**: https://www.x3dom.org/
- **Docs / node reference**: https://doc.x3dom.org/
- **Examples**: https://www.x3dom.org/examples/
- **Repo**: https://github.com/x3dom/x3dom
- **X3D standard (Web3D Consortium)**: https://www.web3d.org/x3d/ — X3DOM implements a browser-friendly subset/profile
- **Tutorials**: https://www.x3dom.org/tutorials/

## Installation & Setup

### CDN (release build)
```html
<link rel="stylesheet" href="https://www.x3dom.org/release/x3dom.css">
<script src="https://www.x3dom.org/release/x3dom.js"></script>
```

### Package manager
```bash
npm install x3dom
# import 'x3dom/x3dom.js'; import 'x3dom/x3dom.css';
```
X3DOM auto-initializes on `DOMContentLoaded`, scanning for `<x3d>` elements. For dynamically inserted markup call `x3dom.reload()`.

## Core Syntax / API Reference

### Minimal scene
`<x3d>` is the canvas host; `<scene>` is the root; a `<shape>` pairs geometry with an `<appearance>`.
```html
<x3d width="600px" height="400px">
  <scene>
    <viewpoint position="0 0 10" orientation="0 1 0 0"></viewpoint>
    <shape>
      <appearance><material diffuseColor="0.3 0.5 1"></material></appearance>
      <box size="2 2 2"></box>
    </shape>
  </scene>
</x3d>
```
All numeric attributes are **space-separated strings** (SFVec3f/MFVec3f), not JSON. Colors are `0–1` floats `"r g b"`, NOT hex.

### Geometry nodes
```html
<box size="2 2 2"></box>
<sphere radius="1.5"></sphere>
<cone bottomRadius="1" height="2"></cone>
<cylinder radius="1" height="2"></cylinder>
<indexedFaceSet coordIndex="0 1 2 -1">   <!-- custom mesh; -1 ends a face -->
  <coordinate point="0 0 0 1 0 0 0 1 0"></coordinate>
</indexedFaceSet>
<indexedLineSet coordIndex="0 1 -1"><coordinate point="0 0 0 1 1 0"></coordinate></indexedLineSet>
<pointSet><coordinate point="0 0 0 1 1 1"></coordinate></pointSet>
<elevationGrid xDimension="3" zDimension="3" height="0 1 0 1 2 1 0 1 0"></elevationGrid>
<text string='"Hello"'><fontStyle size="1"></fontStyle></text>
```

### Appearance & material
```html
<appearance>
  <material diffuseColor="1 0.4 0.1"
            specularColor="1 1 1"
            emissiveColor="0 0 0"
            shininess="0.4"
            transparency="0.2"></material>
  <imagetexture url="wood.jpg"></imagetexture>
</appearance>
<!-- Physically based (PBR) alternative: -->
<appearance>
  <physicalmaterial baseColor="0.8 0.2 0.2" metallic="0.1" roughness="0.4"></physicalmaterial>
</appearance>
```

### Transforms & grouping
```html
<transform translation="3 0 0" rotation="0 1 0 0.785" scale="1 1 1">
  <shape>…</shape>
</transform>
<group>…</group>
<switch whichChoice="0">…</switch>   <!-- show one child -->
```
`rotation` is **axis-angle**: `"x y z angleInRadians"`.

### Cameras, lights, navigation
```html
<viewpoint position="0 2 10" orientation="1 0 0 -0.2" fieldOfView="0.785"></viewpoint>
<directionallight direction="0 -1 -1" intensity="1" color="1 1 1"></directionallight>
<pointlight location="0 5 0" intensity="1"></pointlight>
<spotlight location="0 5 0" direction="0 -1 0" cutOffAngle="0.5"></spotlight>
<navigationInfo type='"EXAMINE" "WALK" "FLY" "ANY"'></navigationInfo>
```

### External models & inlining
```html
<inline url="building.x3d"></inline>   <!-- include another X3D file -->
<!-- glTF / OBJ via ExternalGeometry or the ModelLoader in newer builds -->
```

## Supported Content / Output Types
- **Primitives**: box, sphere, cone, cylinder.
- **Meshes**: IndexedFaceSet, IndexedTriangleSet, IndexedLineSet, PointSet, ElevationGrid.
- **Text** with FontStyle.
- **CAD/legacy**: X3D `.x3d`/`.x3dv`, VRML `.wrl` (import), plus binary geometry (`BinaryGeometry`, `ExternalGeometry`) for large datasets.
- **Geospatial**: `GeoViewpoint`, `GeoLocation`, `GeoElevationGrid` (GeoSpatial component).
- **Environment**: Background, Fog, ImageBackground.

### Runtime API (per-element)
Each `<x3d>` exposes a `runtime` object for imperative control:
```javascript
const x3d = document.querySelector('x3d');
x3d.runtime.showAll();                 // fit view to scene
x3d.runtime.getActiveBindable('Viewpoint');
x3d.runtime.nextView(); x3d.runtime.resetView();
x3d.runtime.getWidth(); x3d.runtime.getHeight();
const png = x3d.runtime.getScreenshot();   // data URL
x3d.runtime.togglePoints();            // debug: show vertices
```

## How-To

### How to add colors, materials & lighting (mandatory styling recipe)
Color is `diffuseColor` on a `<material>`, as `0–1` RGB floats (divide hex by 255). Lighting is declarative nodes; add a headlight or explicit lights so materials aren't flat.
```html
<x3d width="640" height="420">
  <scene>
    <background skyColor="0.06 0.06 0.09"></background>
    <navigationInfo headlight="true" type='"EXAMINE"'></navigationInfo>
    <directionallight direction="-0.5 -1 -0.5" intensity="1.2" color="1 1 0.95"></directionallight>

    <transform rotation="0 1 0 0.4">
      <shape>
        <appearance>
          <material diffuseColor="0.31 0.55 1.0"
                    specularColor="1 1 1" shininess="0.5"
                    emissiveColor="0.0 0.02 0.08"></material>
        </appearance>
        <box size="2 2 2"></box>
      </shape>
    </transform>
  </scene>
</x3d>
```
For realistic reflectance use `<physicalmaterial baseColor metallic roughness>` instead of the classic Phong `<material>`. To texture, add `<imagetexture url="…">` inside `<appearance>`.

### How to animate with the ROUTE/interpolator system
X3D animates declaratively: a `TimeSensor` drives an interpolator, whose output is `ROUTE`d to a field.
```html
<timeSensor DEF="clock" cycleInterval="4" loop="true"></timeSensor>
<orientationInterpolator DEF="spin" key="0 0.5 1"
    keyValue="0 1 0 0  0 1 0 3.14  0 1 0 6.28"></orientationInterpolator>
<transform DEF="spinner"><shape>…</shape></transform>
<ROUTE fromNode="clock" fromField="fraction_changed"
       toNode="spin" toField="set_fraction"></ROUTE>
<ROUTE fromNode="spin" fromField="value_changed"
       toNode="spinner" toField="rotation"></ROUTE>
```

### How to manipulate the scene from JavaScript
Because nodes are DOM, just set attributes:
```javascript
const mat = document.querySelector('material');
mat.setAttribute('diffuseColor', '1 0 0');
document.querySelector('transform').setAttribute('translation', '0 3 0');
```

### How to react to clicks (TouchSensor / DOM events)
```html
<shape onclick="this.querySelector('material').setAttribute('diffuseColor','1 1 0')">
  <appearance><material diffuseColor="0.5 0.5 1"></material></appearance>
  <sphere radius="1.5"></sphere>
</shape>
```

## Do's and Don'ts

### ✅ Do
- Use `0–1` float RGB for all colors (`diffuseColor="1 0.5 0"`), not hex.
- Use `<inline>` / `BinaryGeometry` / LOD for large or repeated content.
- Call `x3dom.reload()` after injecting `<x3d>` markup dynamically.
- Add a `<directionallight>` or keep the navigationInfo `headlight` on so shapes are shaded.
- Prefer `<physicalmaterial>` when you want modern PBR shading.

### ❌ Don't
- Don't write hex colors or JSON — attributes are space-separated float strings.
- Don't confuse `rotation` (axis-angle, radians) with Euler degrees.
- Don't put thousands of individual `<shape>` nodes in the DOM — use IndexedFaceSet/BinaryGeometry; DOM overhead is real.
- Don't forget `-1` face terminators in `coordIndex`.
- Don't expect the full three.js material/post-processing pipeline — X3DOM targets the X3D spec surface.

## Styling, Theming & Customization
- **Background**: `<background skyColor>` (gradient via multiple values + `skyAngle`) or `<imagebackground>` for a skybox.
- **Fog**: `<fog color fogType="LINEAR|EXPONENTIAL" visibilityRange>`.
- **Textures**: `<imagetexture>`, `<multitexture>`, `<movietexture>` (video), `<composedcubemaptexture>` (env reflections).
- **CSS** styles the host `<x3d>` element (size, border) but not the 3D content — that's material/light nodes.
- **PBR** via `<physicalmaterial>` for metallic/roughness workflows.

## Advanced Features
- **Binary geometry** (`BinaryGeometry`, `ExternalGeometry`, `POPGeometry`) for progressive/large mesh streaming.
- **Geospatial** component for globe/terrain coordinates.
- **Shaders**: `<composedshader>` with `<shaderpart type="VERTEX|FRAGMENT">` for custom GLSL.
- **CAD component** nodes for engineering assemblies.
- **Runtime API**: `element.runtime` gives `getActiveBindable`, `showAll()`, screenshot, viewpoint control.

## Common Pitfalls & Troubleshooting
- **Nothing renders** — WebGL context failed, or `x3dom.css` missing (the element collapses to 0 height). Set explicit `width`/`height` on `<x3d>`.
- **Everything is black/flat** — no lights and headlight disabled. Turn on `<navigationInfo headlight="true">` or add a light.
- **Colors look wrong** — you used hex or 0–255 values; must be 0–1 floats.
- **Dynamic markup ignored** — call `x3dom.reload()` after DOM insertion.
- **Mesh has holes/inside-out faces** — winding order / missing `-1` in `coordIndex`, or `solid="true"` culling backfaces (set `solid="false"`).
- **Large model slow** — thousands of DOM shape nodes; switch to binary/indexed geometry.

## Integration Notes
- Works in plain HTML, and inside React/Vue/Angular as raw markup (be sure to trigger `x3dom.reload()` after mount for dynamically created nodes).
- Content authored in Blender/CAD can be exported to X3D/VRML then embedded via `<inline>`.

## Best For / Avoid For
`declarative-3d`, `cad-web-viewing`, `x3d-vrml-content`, `educational-3d`, `dom-driven-3d` — choose X3DOM when you want 3D as HTML markup, need X3D/VRML compatibility, or want to manipulate 3D with standard DOM APIs.
Avoid for: high-end games/PBR-heavy scenes (use three.js/PlayCanvas), React-idiomatic apps (R3F), or when you need the modern post-processing pipeline.

## See Also
- `three_js.md` — imperative WebGL scene graph
- `react-three-fiber.md` — declarative 3D the React way
- `webgl.md` — the raw layer underneath
- `../use-case/3d-graphics.md` — choosing a 3D solution
