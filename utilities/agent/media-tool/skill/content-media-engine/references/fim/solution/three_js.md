# Three.js — WebGL/WebGPU 3D scene-graph library

Three.js is the de-facto standard JavaScript library for real-time 3D on the web. It wraps WebGL (and, increasingly, WebGPU) behind a scene-graph API: you build a `Scene` of `Object3D` nodes (meshes, lights, cameras, groups), then a `WebGLRenderer` rasterizes it each frame. It renders to a `<canvas>` in any modern browser and powers 3D product configurators, data viz, games, VR/AR (WebXR), and generative art.

**Current Version**: r169+ (npm `three@0.169.0`, "current major" is the `0.16x` line, ~monthly releases) **License**: MIT **Bundle/Runtime**: ~600 KB min (core), ~150 KB gzipped; tree-shakeable via ESM. Ships `three` (WebGLRenderer) and `three/webgpu` (WebGPURenderer + TSL node materials).

## Official Resources & Documentation
- **Docs**: https://threejs.org/docs/
- **Examples** (canonical copy-paste source): https://threejs.org/examples/
- **Manual / fundamentals**: https://threejs.org/manual/
- **Repo**: https://github.com/mrdoob/three.js
- **npm**: https://www.npmjs.com/package/three
- **Editor** (live scene builder): https://threejs.org/editor/
- **Ecosystem**: three.js Journey (course), Discord `discord.gg/56GBJwAnUS`, `three/examples/jsm/` add-ons (controls, loaders, post-processing).

## Installation & Setup

### Package manager
```bash
npm install three
# add-ons (loaders, controls, post-processing) live under the same package:
#   import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
```

### CDN / import map (browser, no bundler)
```html
<script type="importmap">
{ "imports": {
    "three": "https://cdn.jsdelivr.net/npm/three@0.169.0/build/three.module.js",
    "three/addons/": "https://cdn.jsdelivr.net/npm/three@0.169.0/examples/jsm/"
} }
</script>
<script type="module">
  import * as THREE from 'three';
  import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
</script>
```

### Import styles
```javascript
import * as THREE from 'three';                              // namespace
import { Scene, PerspectiveCamera, WebGLRenderer } from 'three'; // named (tree-shakes)
// WebGPU + TSL (node materials):
import * as THREE from 'three/webgpu';
import { color, uv, texture } from 'three/tsl';
```
Do NOT load the legacy global `three.min.js` non-module build — it was removed. Always use the ES module build.

## Core API Reference

### The four required objects
Every three.js program needs a scene, a camera, a renderer, and a render call.
```javascript
const scene    = new THREE.Scene();
const camera   = new THREE.PerspectiveCamera(75, innerWidth / innerHeight, 0.1, 1000);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(innerWidth, innerHeight);
renderer.setPixelRatio(Math.min(devicePixelRatio, 2)); // cap DPR for perf
document.body.appendChild(renderer.domElement);
renderer.render(scene, camera);
```

### Cameras
```javascript
new THREE.PerspectiveCamera(fov, aspect, near, far);   // fov in degrees; realistic
new THREE.OrthographicCamera(left, right, top, bottom, near, far); // CAD / 2D / isometric
camera.position.set(0, 2, 5);
camera.lookAt(0, 0, 0);
camera.aspect = innerWidth / innerHeight;
camera.updateProjectionMatrix(); // call after changing fov/aspect/near/far
```

### Geometry (the shape)
```javascript
new THREE.BoxGeometry(w, h, d);
new THREE.SphereGeometry(radius, widthSeg, heightSeg);
new THREE.PlaneGeometry(w, h, wSeg, hSeg);
new THREE.CylinderGeometry(rTop, rBottom, height, radialSeg);
new THREE.TorusGeometry(radius, tube, radialSeg, tubularSeg);
new THREE.TorusKnotGeometry();
new THREE.ConeGeometry(radius, height, radialSeg);
new THREE.CircleGeometry(radius, seg);
new THREE.IcosahedronGeometry(radius, detail); // + Dodeca/Octa/Tetrahedron
new THREE.ExtrudeGeometry(shape, options);     // extrude a THREE.Shape
new THREE.LatheGeometry(points);               // revolve a profile
// Custom: build from typed arrays
const g = new THREE.BufferGeometry();
g.setAttribute('position', new THREE.BufferAttribute(new Float32Array([...]), 3));
g.setIndex([0, 1, 2]);
g.computeVertexNormals();
```

### Materials (the surface)
```javascript
new THREE.MeshBasicMaterial({ color: 0x00ff00 });    // unlit, flat — ignores lights
new THREE.MeshStandardMaterial({ color, metalness, roughness, map, normalMap }); // PBR (default choice)
new THREE.MeshPhysicalMaterial({ clearcoat, transmission, ior, sheen });         // PBR+ (glass, car paint)
new THREE.MeshPhongMaterial({ color, shininess, specular });   // cheaper legacy specular
new THREE.MeshLambertMaterial({ color });                       // cheap diffuse-only
new THREE.MeshNormalMaterial();                                 // debug: normals → RGB
new THREE.MeshDepthMaterial();
new THREE.PointsMaterial({ size, sizeAttenuation });            // particles
new THREE.LineBasicMaterial({ color });
new THREE.ShaderMaterial({ vertexShader, fragmentShader, uniforms }); // custom GLSL
new THREE.SpriteMaterial({ map });                              // always-facing billboard
// Common flags:
material.side = THREE.DoubleSide;   // FrontSide (default) | BackSide | DoubleSide
material.transparent = true; material.opacity = 0.5;
material.wireframe = true;
```
`MeshStandardMaterial`/`MeshPhysicalMaterial` need lights AND (for realism) an environment map. `MeshBasicMaterial` is the only common material that shows up without any light.

### Mesh, Points, Line, Group
```javascript
const mesh = new THREE.Mesh(geometry, material);
mesh.position.set(x, y, z);
mesh.rotation.set(rx, ry, rz);   // Euler radians
mesh.scale.set(sx, sy, sz);
mesh.castShadow = true; mesh.receiveShadow = true;
scene.add(mesh);

const points = new THREE.Points(geometry, pointsMaterial);
const line   = new THREE.Line(geometry, lineMaterial);
const group  = new THREE.Group();  // transform children together
group.add(meshA, meshB);
```

### Lights
```javascript
new THREE.AmbientLight(0xffffff, 0.3);            // flat fill, no direction/shadow
new THREE.HemisphereLight(0xffffbb, 0x080820, 1); // sky/ground gradient fill
new THREE.DirectionalLight(0xffffff, 1);          // sun; parallel rays; casts shadows
new THREE.PointLight(0xffffff, 1, 100, 2);        // bulb; (color,intensity,distance,decay)
new THREE.SpotLight(0xffffff, 1, 0, Math.PI/6);   // cone
new THREE.RectAreaLight(0xffffff, 5, 4, 2);       // soft panel (Standard/Physical only)
// Shadows: opt-in on renderer, light, caster, and receiver
renderer.shadowMap.enabled = true;
dirLight.castShadow = true;
dirLight.shadow.mapSize.set(2048, 2048);
```

### Render / animation loop
```javascript
const clock = new THREE.Clock();
renderer.setAnimationLoop(() => {        // preferred over requestAnimationFrame (WebXR-safe)
  const dt = clock.getDelta();           // seconds since last frame — use for frame-rate-independent motion
  mesh.rotation.y += dt * 0.5;
  controls.update();
  renderer.render(scene, camera);
});
```

### Loaders (`three/addons/loaders/…`)
```javascript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
const gltf = await new GLTFLoader().loadAsync('model.glb'); // glTF/GLB = preferred 3D format
scene.add(gltf.scene);
// Textures:
const tex = await new THREE.TextureLoader().loadAsync('albedo.jpg');
tex.colorSpace = THREE.SRGBColorSpace;  // color textures need sRGB; data maps (normal/roughness) do NOT
// HDR environment:
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';
const env = await new RGBELoader().loadAsync('studio.hdr');
env.mapping = THREE.EquirectangularReflectionMapping;
scene.environment = env; scene.background = env;
```

### Controls (`three/addons/controls/…`)
```javascript
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;   // inertia; requires controls.update() each frame
// Also: MapControls, TrackballControls, FlyControls, FirstPersonControls, PointerLockControls, ArcballControls, TransformControls (gizmo)
```

## Output Types / Renderers
- **WebGLRenderer** — default; WebGL2 context. Broadest support.
- **WebGPURenderer** (`three/webgpu`) — modern GPU API + compute; author shaders in **TSL** (Three Shading Language, JS-based node graph) instead of GLSL. Falls back to WebGL2.
- **CSS3DRenderer / CSS2DRenderer** — render DOM elements positioned in 3D space (labels, HTML overlays).
- **SVGRenderer** — vector output for simple scenes.
- **WebXR** — VR/AR via `renderer.xr.enabled = true` + `VRButton`/`ARButton`.

## How-To

### How to add colors, materials & lighting (mandatory styling recipe)
Color in three.js lives on the material; realistic shading needs a PBR material + light + (ideally) an environment map. Colors are `THREE.Color` — accept hex `0xff8800`, CSS strings `'tomato'`, or `.setHSL(h,s,l)`.
```javascript
// PBR sphere lit by a key light + soft environment
const mat = new THREE.MeshStandardMaterial({
  color: new THREE.Color('#4f8cff'),
  metalness: 0.1,
  roughness: 0.4,
  emissive: new THREE.Color('#001133'), // self-glow, unaffected by lights
});
scene.add(new THREE.Mesh(new THREE.SphereGeometry(1, 64, 64), mat));

scene.add(new THREE.HemisphereLight('#bcd8ff', '#33221a', 0.6)); // ambient fill
const key = new THREE.DirectionalLight('#ffffff', 2.5);
key.position.set(5, 8, 3);
scene.add(key);

renderer.outputColorSpace = THREE.SRGBColorSpace;       // correct on-screen color
renderer.toneMapping = THREE.ACESFilmicToneMapping;     // filmic highlights
renderer.toneMappingExposure = 1.0;
```
Rule of thumb: **sRGB for renderer output and color textures; linear for data maps.** Skipping tone mapping + sRGB is the #1 cause of "my three.js scene looks washed-out / too dark."

### How to make objects move (frame-rate-independent)
```javascript
const clock = new THREE.Clock();
renderer.setAnimationLoop(() => {
  const t = clock.getElapsedTime();
  mesh.position.y = Math.sin(t * 2) * 0.5;   // bob
  mesh.rotation.y += clock.getDelta() * 1.2; // spin, scaled by delta
  renderer.render(scene, camera);
});
```

### How to handle window resize
```javascript
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
});
```

### How to render thousands of copies cheaply (InstancedMesh)
```javascript
const count = 10000;
const inst = new THREE.InstancedMesh(new THREE.BoxGeometry(), mat, count);
const dummy = new THREE.Object3D();
for (let i = 0; i < count; i++) {
  dummy.position.set(Math.random()*40-20, Math.random()*40-20, Math.random()*40-20);
  dummy.updateMatrix();
  inst.setMatrixAt(i, dummy.matrix);
}
inst.instanceMatrix.needsUpdate = true;
scene.add(inst); // ONE draw call for all 10k
```

### How to pick objects with the mouse (raycasting)
```javascript
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();
addEventListener('pointerdown', (e) => {
  pointer.x = (e.clientX / innerWidth) * 2 - 1;
  pointer.y = -(e.clientY / innerHeight) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);
  const hit = raycaster.intersectObjects(scene.children, true)[0];
  if (hit) hit.object.material.color.set('red');
});
```

## Do's and Don'ts

### ✅ Do
- Reuse geometries and materials across meshes — creating them per-frame leaks GPU memory.
- Set `renderer.outputColorSpace = SRGBColorSpace` and a tone mapping mode for correct color.
- Use `setAnimationLoop` (not `requestAnimationFrame`) so WebXR works.
- Dispose of what you remove: `geometry.dispose(); material.dispose(); texture.dispose();`.
- Cap pixel ratio: `setPixelRatio(Math.min(devicePixelRatio, 2))` — retina at 3× quadruples fragment cost.
- Prefer **glTF/GLB** for models; use `InstancedMesh` / `BatchedMesh` for repeated geometry.

### ❌ Don't
- Don't use `MeshStandardMaterial` with no lights and no `scene.environment` and expect to see anything but black.
- Don't create `new THREE.Vector3()` / geometries inside the render loop — allocate once, mutate.
- Don't forget `camera.updateProjectionMatrix()` after changing camera params.
- Don't set `material.transparent = true` unnecessarily — it forces expensive depth sorting and z-fighting.
- Don't add unbounded objects without removing/disposing — the scene graph retains everything you `add`.

## Styling, Theming & Customization
- **Environment maps** define reflections and image-based lighting: `scene.environment = hdrTexture`. This is what makes PBR materials look "real."
- **Fog**: `scene.fog = new THREE.Fog(0x223344, 5, 50)` or `FogExp2` for depth cueing / mood.
- **Background**: `scene.background = new THREE.Color('#101018')` or an equirect texture / `CubeTexture`.
- **Tone mapping**: `NoToneMapping | LinearToneMapping | ReinhardToneMapping | CineonToneMapping | ACESFilmicToneMapping | AgXToneMapping`. AgX/ACES give film-like rolloff.
- **Custom shaders** via `ShaderMaterial` (GLSL) or `onBeforeCompile` to patch a built-in material; on WebGPU use **TSL** node graphs.

## Advanced Features
- **Post-processing** (`three/addons/postprocessing/`): `EffectComposer` + passes (`RenderPass`, `UnrealBloomPass`, `SSAOPass`, `OutlinePass`, `SMAAPass`, `BokehPass`). Or the newer **`pmndrs/postprocessing`** package.
- **Shadows**: `PCFSoftShadowMap`, `VSMShadowMap`; tune `shadow.camera` frustum + `shadow.bias` to kill acne/peter-panning.
- **Animation system**: `AnimationMixer` + `AnimationClip` (from glTF) for skeletal/morph animation.
- **WebXR**: `renderer.xr.enabled = true`; append `VRButton.createButton(renderer)`.
- **Compute** (WebGPU): storage buffers + TSL compute nodes for GPU particle sims.
- **BatchedMesh**: multi-geometry batching in a single draw call (newer than InstancedMesh).

## Common Pitfalls & Troubleshooting
- **Black screen** — no light + PBR material, or camera inside/behind the object, or `near/far` clipping. Add an `AmbientLight` to sanity-check.
- **Washed-out / dark colors** — missing sRGB output color space or tone mapping; color texture not marked `SRGBColorSpace`.
- **Model loads but is invisible** — scale mismatch (glTF often in meters vs a tiny camera frustum) or missing lights. Log `gltf.scene` bounding box.
- **Z-fighting / flicker** — coplanar surfaces or `near` too small / `far` too large (poor depth precision). Widen `near`, use `logarithmicDepthBuffer` for huge scenes.
- **Memory growth in SPAs** — undisposed geometries/materials/textures/render targets; call `renderer.dispose()` and dispose resources on unmount.
- **`THREE.Geometry` not found** — removed years ago; use `BufferGeometry`.
- **CORS on textures/models** — serve over http(s), set `crossOrigin`, and host assets same-origin or with CORS headers.

## Integration Notes
- **React**: use **react-three-fiber** (see `react-three-fiber.md`) rather than manual imperative code.
- **Vue/Svelte/Angular**: TresJS, Threlte, or plain refs to a canvas.
- **Bundlers**: Vite/webpack tree-shake named imports; DRACO/KTX2 decoders need their WASM copied to a static path.
- **SSR/Next.js**: three.js is client-only — guard with dynamic import / `useEffect`; there is no DOM/WebGL on the server.

## Best For / Avoid For
`interactive-3d`, `product-configurators`, `3d-data-visualization`, `webxr`, `generative-3d-art`, `games` — choose three.js when you need full control over the 3D pipeline.
Avoid for: simple 2D (use Canvas/SVG/PixiJS), no-code scenes (use Spline), pure declarative React scenes where R3F is cleaner, or 3D globes at planet scale (use CesiumJS).

## See Also
- `react-three-fiber.md` — declarative React wrapper over this exact API
- `webgl.md` — the raw layer three.js sits on top of
- `playcanvas.md`, `verge3d.md`, `spline.md` — higher-level/editor-driven 3D engines
- `x3dom.md` — declarative HTML 3D alternative
- `../use-case/3d-graphics.md` — when to pick three.js vs siblings
- `three_js/use-case/` — task-specific three.js recipes
