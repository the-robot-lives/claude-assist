# Verge3D — artist-driven interactive 3D web toolkit

Verge3D by Soft8Soft turns Blender, 3ds Max, or Maya scenes into interactive WebGL applications. Artists model, texture, and light in their DCC tool, export a glTF-based bundle, and wire behavior with **Puzzles** — a visual, block-based (Blockly-style) logic editor — so a lot of interactivity ships with zero hand-written JS. Under the hood the runtime is a customized fork of three.js, so a JavaScript API (`v3d.*`) is also available for advanced control. It's aimed at product configurators, e-commerce, e-learning, and marketing experiences.

**Current Version**: 4.x (Blender/Max/Maya editions; "current major") **License**: Commercial (paid; free trial/eval). Not open source. **Bundle/Runtime**: `v3d.js` runtime (three.js-derived) + exported glTF/GLB scene + `visual_logic.js` (Puzzles output).

## Official Resources & Documentation
- **Site**: https://www.soft8soft.com/verge3d/
- **User manual**: https://www.soft8soft.com/docs/manual/en/
- **Puzzles reference**: https://www.soft8soft.com/docs/manual/en/puzzles/
- **API (`v3d`) reference**: https://www.soft8soft.com/docs/api/
- **Asset store / demos**: https://www.soft8soft.com/product-category/
- **Forums**: https://www.soft8soft.com/forums/

## Installation & Setup
Verge3D is installed as a **plugin/add-on inside your DCC app** (Blender/3ds Max/Maya), not via npm. The App Manager scaffolds a web app; you deploy the exported folder.

### Include the runtime (exported app)
```html
<script src="v3d.js"></script>
<script src="app.js"></script>       <!-- generated app bootstrap -->
<div id="v3d-container"></div>
```
The CDN-style loader script in stubs is an eval/hosted convenience; production apps ship the runtime from your own server or Verge3D Network/Cloud.

## Core Syntax / API Reference
Most projects never touch JS — logic lives in Puzzles. When you do use the API, `v3d.App` is the entry point (a thin three.js-derived application shell).

### Bootstrapping an app
```javascript
const app = new v3d.App('v3d-container', null, new v3d.SimplePreloader({ container: 'v3d-container' }));

app.loadScene('scene.gltf', () => {
  app.enableControls();          // orbit/examine controls
  app.run();                     // start render loop
});
```

### Traversing & manipulating loaded objects
The scene graph is three.js-like (`app.scene`, `Object3D`, `material`, `position`).
```javascript
app.scene.traverse((obj) => {
  if (obj.name === 'Product') {
    obj.material.color.setHex(0xff0000);  // three.js Color API
  }
});
const cam = app.getCamera();
```

### Puzzles (visual logic) — the primary "syntax"
Puzzles are exported to `visual_logic.js` and cover events, scene queries, animation, materials, variables, media, physics, AR/VR, and network/REST. Conceptually:
```text
[when clicked: "BuyButton"] → [play animation: "OpenBox"] → [set material color: "Lid" to #22aa55]
[when scene loaded]         → [set variable: price = 199] → [HTML: set text of #price]
```
You author these in the browser-based Puzzles editor; there is no textual DSL to hand-write — the block graph IS the program.

### Puzzles block categories (the toolbox)
The Puzzles palette is grouped; knowing the groups tells you what interactivity is achievable no-code:
- **Init** — one-time setup on scene load.
- **Events** — `when clicked/hovered/dragged`, `on key`, `on load`, timers.
- **Scene** — select objects, show/hide, move/rotate/scale, parent, clone, morph.
- **Animation** — play/stop annotation, play glTF animation clips, tween properties.
- **Materials** — set base color / metalness / roughness / opacity / texture, swap materials.
- **Media** — play sound/video, set HTML text/attribute/class, show/hide DOM.
- **Variables & Logic** — variables, math, lists, conditionals, loops.
- **Physics** — enable rigid bodies, apply force/impulse, collision events (Ammo).
- **Camera** — move camera, look at, orbit limits, viewpoints.
- **AR/VR** — enter WebXR, place on surface, controllers.
- **Network** — REST GET/POST, load external data, WooCommerce/Shopify actions.

### Calling JS from Puzzles (and back)
- Puzzles `exec script` block runs arbitrary JS inline.
- Expose functions to Puzzles via `window`-scoped callbacks; call them from a Puzzles `call JS function` block.
- Read/write Puzzles variables from JS through the app's variable store; changes propagate to bound materials/HTML.

### Common `v3d.App` API surface (advanced/code path)
```javascript
app.loadScene(url, onLoad, onProgress, onError);
app.enableControls();  app.disableControls();
app.getCamera();  app.setCamera(entity);
app.scene;  app.renderer;  app.controls;   // three.js-derived objects
app.getObjectByName('Product');            // three.js traversal
app.dispose();                             // free the app on teardown
```

## Supported Content / Output Types
- **Interactive product configurators** (swap materials, colors, parts).
- **E-commerce 3D** (Shopify/WooCommerce integration puzzles, order/price logic).
- **E-learning / simulations** (guided steps, quizzes).
- **AR/VR** via WebXR (`WebXR` puzzles; AR on supported mobile).
- **Animations** authored in the DCC (armatures, shape keys, camera moves) triggered by Puzzles.
- Output is a **self-contained web folder** (HTML + `v3d.js` + glTF + assets + `visual_logic.js`).

## How-To

### How to add/change colors, materials & lighting (mandatory styling recipe)
Base look is authored in Blender/Max/Maya (PBR materials, HDRI environment, lights) and preserved through glTF export. To change color at runtime, target the material — via Puzzles or JS.

Puzzles:
```text
[when clicked: "Sofa"] → [set material "Fabric" color to (H:210 S:80 L:55)]
```
JavaScript:
```javascript
app.scene.traverse((o) => {
  if (o.name === 'Sofa' && o.material) {
    o.material.color.set('#3a7bd5');   // diffuse/base color
    o.material.metalness = 0.1;
    o.material.roughness = 0.5;
    o.material.needsUpdate = true;
  }
});
```
For lighting/reflections, set up an **HDRI environment and lights in the DCC** before export — Verge3D uses image-based lighting like three.js. Enable `useHDR`/SSAO/shadows in app settings for richer output. Colors follow three.js `Color` (hex, CSS strings, HSL).

### How to make objects interactive without code
1. Name objects meaningfully in Blender (e.g. `Button`, `Lid`).
2. In Puzzles: drag a `when clicked` event, connect to `play animation` / `set material` / `show HTML` blocks.
3. Preview in the App Manager; export.

### How to drive an e-commerce configurator
```text
[on click: color swatch "Red"]  → [set material "Body" base color #cc2222]
                                 → [set variable: selectedColor = "Red"]
[on click: "AddToCart"]         → [REST POST to /cart with variable selectedColor]
```

### How to load and switch scenes
```javascript
app.loadScene('variant-b.gltf', () => app.run());
```

### How to play a DCC-authored animation on interaction
Author armature/camera/shape-key animation in Blender; name the clip; trigger via Puzzles:
```text
[when clicked: "Door"] → [play animation "DoorOpen" on "Door"]  (once, forward)
[when clicked: "Door" again] → [play animation "DoorOpen"] (reversed)
```
Or in code, use the three.js-derived mixer exposed by the app to play `AnimationClip`s loaded from glTF.

### How to wire a REST/backend call (no server code in the runtime)
```text
[on click "Submit"]
  → [set variable: payload = { color: selectedColor, qty: 1 }]
  → [REST POST to "https://api.example.com/order" with payload]
  → [on success] → [set HTML text of "#status" to "Ordered!"]
```
Keep secrets server-side — Puzzles REST calls run in the browser, so never embed private keys.

## Do's and Don'ts

### ✅ Do
- Author materials, lighting, and HDRI in the DCC tool — Verge3D faithfully renders glTF PBR.
- Name objects/materials clearly; Puzzles and the API select by name.
- Use Puzzles for logic first; drop to JS only for what Puzzles can't express.
- Optimize meshes/textures in the DCC (decimate, bake, compress) before export.
- Use LODs and texture compression (KTX2/Basis) for heavy scenes.

### ❌ Don't
- Don't expect to generate scenes purely in code — Verge3D is authoring-tool-centric; programmatic scene construction is limited vs three.js.
- Don't ship without a license for production — it's commercial software.
- Don't rely on unnamed objects — selection is name-based.
- Don't skip DCC-side optimization and expect mobile to cope with raw high-poly assets.

## Styling, Theming & Customization
- **Environment/IBL**: HDRI set in the DCC world settings; toggles for HDR, SSAO, bloom, shadows in app config.
- **Materials**: full glTF PBR (base color, metallic, roughness, normal, emissive, clearcoat) plus Verge3D node extensions in the Blender shader editor.
- **Post-processing**: bloom, SSAO, outline, DOF exposed as settings/puzzles.
- **UI/HTML overlay**: standard HTML/CSS layered over the canvas; Puzzles can set text/attributes on DOM elements.

## Advanced Features
- **Physics** (Puzzles physics blocks; Ammo-based).
- **WebXR** AR/VR puzzles.
- **REST/networking** puzzles for backend integration, plus WooCommerce/Shopify connectors.
- **Custom GLSL** node materials in Blender carry over.
- **Verge3D Network / Cloud** for hosting and short links.

## Common Pitfalls & Troubleshooting
- **Runtime script won't load** — the hosted loader URL is account-scoped; ship `v3d.js` from your own deploy for production.
- **Object not clickable** — object unnamed, or Puzzles event targets the wrong name; check the outliner names.
- **Washed-out/dark render** — HDRI/tone-mapping not configured; enable HDR and correct exposure in app settings.
- **Huge download** — uncompressed textures/geometry; enable Draco/KTX2 and downscale textures in export settings.
- **Animation doesn't play** — clip name mismatch between DCC and the Puzzles `play animation` block.

## Export & Optimization Settings
- **glTF vs GLB**: GLB (binary) bundles geometry+textures in one file — preferred for deploy; glTF+separate assets is friendlier for debugging.
- **Compression**: enable **Draco** (geometry) and **KTX2/Basis** (textures) in export settings to cut payload dramatically.
- **Textures**: downscale to the smallest size that looks right; bake lighting/AO where possible instead of runtime shadows.
- **LODs**: author level-of-detail variants for complex products so distant/mobile views load lighter geometry.
- **Shadows/SSAO/bloom**: powerful but costly — gate behind a quality setting or disable on mobile.
- **Preloader**: configure a branded preloader (`SimplePreloader`/custom) since scene payloads take time to fetch.

## Integration Notes
- Exports drop into any static host; integrate with WordPress/WooCommerce/Shopify via provided connectors.
- Can coexist with an existing site by embedding the exported container `<div>` and runtime.
- Because the runtime is three.js-derived, developers comfortable with three.js can drop into the `app.scene`/`app.renderer` objects for effects Puzzles doesn't cover.

## Typical Exported Project Structure
```
my_app/
├── my_app.html            # entry page hosting the <div id="v3d-container">
├── v3d.js                 # runtime (three.js-derived) — ship from your own host
├── my_app.gltf / .glb     # exported scene (geometry, materials, lights, animations)
├── visual_logic.js        # compiled Puzzles graph (your no-code interactivity)
├── app.js                 # generated bootstrap wiring runtime + scene + puzzles
└── media/                 # textures, sounds, HDRIs, external assets
```
Deploy the whole folder to any static host. Re-export from the DCC App Manager whenever the scene or Puzzles change.

## Best For / Avoid For
`product-configurators`, `ecommerce-3d`, `no-code-interactive-3d`, `marketing-experiences`, `e-learning` — choose Verge3D when artists own the scene and you want interactivity without a JS build pipeline.
Avoid for: open-source requirements/budget-zero projects (use three.js/R3F/PlayCanvas), heavily code-generated/procedural scenes, or when you need full low-level rendering control.

## See Also
- `three_js.md` — the library Verge3D's runtime derives from
- `spline.md`, `playcanvas.md` — other editor/engine-driven 3D web tools
- `react-three-fiber.md` — code-first declarative alternative
- `../use-case/3d-graphics.md` — 3D solution selection
