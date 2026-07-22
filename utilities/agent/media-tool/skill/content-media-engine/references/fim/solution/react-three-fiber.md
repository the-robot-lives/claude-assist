# React Three Fiber (R3F) — declarative Three.js for React

React Three Fiber renders a Three.js scene graph through React. Every three.js class becomes a JSX element (`<mesh>`, `<boxGeometry>`, `<meshStandardMaterial>`, `<pointLight>`), reconciled by a custom React renderer. You get the full three.js API — nothing is abstracted away — plus React state, hooks, suspense, and a rich helper ecosystem (`drei`). It runs anywhere React runs the DOM (and via `react-three-fiber` native on some targets).

**Current Version**: `@react-three/fiber@8.x` (React 18) / `9.x` (React 19); pairs with `three@0.16x` **License**: MIT **Bundle/Runtime**: fiber ~50 KB + peer `three` (~150 KB gz). `drei` is modular — import only what you use.

## Official Resources & Documentation
- **Docs**: https://r3f.docs.pmnd.rs/
- **drei helpers**: https://github.com/pmndrs/drei (docs: https://drei.docs.pmnd.rs/)
- **Repo**: https://github.com/pmndrs/react-three-fiber
- **Ecosystem** (pmndrs): `drei`, `@react-three/rapier` (physics), `@react-three/postprocessing`, `@react-three/xr`, `@react-three/cannon`, `leva` (GUI), `zustand` (state)
- **Examples**: https://docs.pmnd.rs/react-three-fiber/getting-started/examples

## Installation & Setup

### Package manager
```bash
npm install three @react-three/fiber
npm install @react-three/drei          # helpers (controls, loaders, shapes, env)
npm install @react-three/postprocessing @react-three/rapier @react-three/xr  # optional
```

### Imports
```jsx
import { Canvas, useFrame, useThree, useLoader, extend } from '@react-three/fiber';
import { OrbitControls, Environment, useGLTF, Instances, Instance } from '@react-three/drei';
```
There is no CDN-only path — R3F requires a React build step (Vite/Next/CRA).

## Core Syntax / API Reference

### `<Canvas>` — the root
`<Canvas>` creates the `Scene`, a default `PerspectiveCamera`, a `WebGLRenderer`, and its own render loop. Everything inside is your scene graph.
```jsx
<Canvas
  camera={{ position: [0, 0, 5], fov: 50, near: 0.1, far: 100 }}
  shadows                                   // enable shadow maps
  dpr={[1, 2]}                              // clamp device pixel ratio [min, max]
  gl={{ antialias: true, toneMapping: THREE.ACESFilmicToneMapping }}
  onCreated={({ gl, scene, camera }) => { /* imperative escape hatch */ }}
>
  {/* scene contents */}
</Canvas>
```

### JSX ↔ three.js mapping
Any three.js class `THREE.Foo` is available as `<foo />` (lowercase first letter). Constructor args go in the `args` prop (as an array, positional). Properties are set as props; nested `.set()`-able props (position, rotation, scale, color) accept arrays.
```jsx
<mesh position={[1, 0, 0]} rotation={[0, Math.PI / 4, 0]} scale={1.5} castShadow>
  <boxGeometry args={[2, 2, 2]} />          {/* new THREE.BoxGeometry(2,2,2) */}
  <meshStandardMaterial color="hotpink" metalness={0.2} roughness={0.4} />
</mesh>
```
- `args` = constructor arguments (only re-runs the constructor when the array changes).
- `attach` = where to bind a non-child object (`<meshStandardMaterial attach="material" />` is implicit; use explicit `attach` for e.g. `<planeGeometry attach="geometry" />`).
- Dashed paths set nested props: `<pointLight position-y={3} />`, `<meshStandardMaterial color-r={1} />`.

### Lights & camera as elements
```jsx
<ambientLight intensity={0.3} />
<hemisphereLight args={['#bcd8ff', '#33221a', 0.6]} />
<directionalLight position={[5, 8, 3]} intensity={2.5} castShadow shadow-mapSize={[2048, 2048]} />
<perspectiveCamera makeDefault position={[0, 2, 6]} fov={45} />
```

### Hooks
```jsx
// Per-frame loop (this is R3F's requestAnimationFrame)
useFrame((state, delta) => {
  ref.current.rotation.y += delta;         // delta = seconds since last frame
  state.camera.position.x = Math.sin(state.clock.elapsedTime);
}, /* renderPriority */ 0);

// Access renderer/scene/camera/size/pointer
const { gl, scene, camera, size, viewport, clock } = useThree();

// Load assets with Suspense (throws a promise until ready)
const texture = useLoader(THREE.TextureLoader, '/albedo.jpg');
const { scene: model } = useGLTF('/model.glb'); // drei — with draco support
```

### `extend` — register custom/add-on classes as JSX
```jsx
import { extend } from '@react-three/fiber';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
extend({ OrbitControls });
// now usable as <orbitControls args={[camera, domElement]} /> (drei's <OrbitControls> does this for you)
```

## Output / What it renders
R3F renders **the same output as three.js** — a WebGL2 (or WebGPU via `@react-three/fiber` + `three/webgpu`) canvas. It is not a separate renderer; it is a React reconciler over three.js objects. Anything three.js can draw (meshes, points, lines, sprites, post-processing, WebXR) R3F can express declaratively.

## How-To

### How to add colors, materials, lighting & environment (mandatory styling recipe)
Color and shading are material + light + environment, same as three.js — but declarative. `drei`'s `<Environment>` gives instant image-based lighting so PBR materials look real.
```jsx
import { Environment } from '@react-three/drei';

function Styled() {
  return (
    <Canvas shadows gl={{ toneMapping: THREE.ACESFilmicToneMapping }}>
      <color attach="background" args={['#101018']} />   {/* scene.background */}
      <fog attach="fog" args={['#101018', 8, 30]} />

      <hemisphereLight args={['#bcd8ff', '#33221a', 0.5]} />
      <directionalLight position={[5, 8, 3]} intensity={2.5} castShadow />

      <mesh castShadow>
        <icosahedronGeometry args={[1, 4]} />
        <meshStandardMaterial color="#4f8cff" metalness={0.1} roughness={0.35}
                              emissive="#001133" />
      </mesh>

      <Environment preset="studio" />   {/* HDRI IBL: city, sunset, studio, dawn, night, warehouse... */}
    </Canvas>
  );
}
```
Set `color` via CSS strings, hex numbers, or `color-r/g/b`. Use `<Environment preset=…>` or `files="/env.hdr"` for reflections — without it, metallic PBR materials look flat/black.

### How to animate
```jsx
function Spinner() {
  const ref = useRef();
  useFrame((_, dt) => (ref.current.rotation.y += dt * 0.8));
  return <mesh ref={ref}><torusKnotGeometry /><meshNormalMaterial /></mesh>;
}
```
For tween/spring easing use `@react-spring/three` or `framer-motion-3d`; for scroll use `drei`'s `<ScrollControls>`.

### How to load a glTF model with Suspense
```jsx
import { Suspense } from 'react';
import { useGLTF } from '@react-three/drei';

function Model() { const { scene } = useGLTF('/robot.glb'); return <primitive object={scene} />; }

export default () => (
  <Canvas><Suspense fallback={null}><Model /></Suspense></Canvas>
);
useGLTF.preload('/robot.glb'); // optional warm-up
```
`<primitive object={…}>` mounts an existing three.js object into the graph.

### How to render many instances declaratively
```jsx
import { Instances, Instance } from '@react-three/drei';
<Instances limit={1000}>
  <boxGeometry /><meshStandardMaterial color="orange" />
  {positions.map((p, i) => <Instance key={i} position={p} />)}  {/* one draw call */}
</Instances>
```

### How to handle pointer events (built-in raycasting)
```jsx
<mesh
  onClick={(e) => { e.stopPropagation(); setActive(a => !a); }}
  onPointerOver={(e) => setHover(true)}
  onPointerOut={() => setHover(false)}
>
  <boxGeometry />
  <meshStandardMaterial color={hover ? 'yellow' : 'gray'} />
</mesh>
```
R3F raycasts for you — event objects carry `point`, `distance`, `face`, `object`. Call `e.stopPropagation()` to avoid hitting occluded meshes.

## Do's and Don'ts

### ✅ Do
- Wrap async assets (`useGLTF`, `useTexture`, `useLoader`) in `<Suspense>`.
- Mutate refs in `useFrame` (`ref.current.position.x = …`) instead of driving transforms through React state — state changes re-render; ref mutation doesn't.
- Use `drei` (`<OrbitControls>`, `<Environment>`, `<Instances>`, `<Text>`, `<Html>`) instead of reinventing.
- Use `args` for constructor params and props for everything else.
- Clamp DPR: `<Canvas dpr={[1, 2]}>`.

### ❌ Don't
- Don't `setState` every frame — that re-renders the React tree 60×/s. Animate via refs.
- Don't create geometries/materials inline in a component that re-renders often without `useMemo` — you'll churn GPU objects.
- Don't put R3F hooks (`useFrame`, `useThree`) **outside** `<Canvas>` — they only work in its React context.
- Don't forget `makeDefault` on custom controls/cameras, or drei helpers won't find them.
- Don't SSR the Canvas — it's client-only (`next/dynamic` with `ssr: false`, or a mount guard).

## Styling, Theming & Customization
- **`<Environment>`** (drei): presets or custom `.hdr` for IBL + background — the fastest route to good-looking materials.
- **Post-processing**: `@react-three/postprocessing` → `<EffectComposer><Bloom/><DepthOfField/><Vignette/></EffectComposer>`.
- **Tone mapping / color space**: set via `gl={{ toneMapping, outputColorSpace }}` on `<Canvas>`.
- **GUI tweaking**: `leva` gives live controls bound to component state.
- **Custom shaders**: `<shaderMaterial>` element, or drei's `shaderMaterial()` factory + `extend`.

## Advanced Features
- **Physics**: `@react-three/rapier` (`<Physics><RigidBody>…`) — the modern choice; `@react-three/cannon` is older.
- **XR**: `@react-three/xr` — `<XR>`, `<Controllers>`, `createXRStore()`.
- **Portals & multiple scenes**: `createPortal`, `<View>` (drei) for multiple viewports in one canvas.
- **Performance scaling**: drei `<PerformanceMonitor>` + `<AdaptiveDpr>` / `<AdaptiveEvents>` auto-degrade under load.
- **State**: `zustand` pairs naturally for shared scene state outside React re-renders.

## drei helper quick-reference (most-used)
| Helper | Purpose |
|---|---|
| `<OrbitControls />` | mouse orbit/zoom/pan camera |
| `<Environment preset=… />` | HDRI image-based lighting + background |
| `<Stage />` | auto camera + lights + environment for a hero object |
| `<Instances>`/`<Instance>` | declarative instanced meshes (one draw call) |
| `<Text>` / `<Html>` | 3D SDF text / DOM overlays in 3D space |
| `useGLTF` / `useTexture` | Suspense-based asset loading (with draco) |
| `<ScrollControls>` / `useScroll` | scroll-driven camera/animation |
| `<PerspectiveCamera makeDefault>` | declarative camera |
| `<Bounds>` / `<Center>` | auto-fit / center content |
| `<ContactShadows>` / `<AccumulativeShadows>` | soft ground shadows |
| `<PerformanceMonitor>` / `<AdaptiveDpr>` | auto-degrade under load |

## Common Pitfalls & Troubleshooting
- **"Cannot read useFrame of undefined" / hooks fail** — hook used outside `<Canvas>`. Move it into a child component rendered inside the canvas.
- **Everything re-mounts / flickers on state change** — you passed a new object/array literal to `args` each render; memoize it.
- **Model invisible** — no lights/environment, wrong scale, or forgot `<Suspense>` (component threw). Add `<Environment>` + an ambient light to debug.
- **Janky animation** — driving transforms through `useState` instead of refs.
- **Next.js "window is not defined"** — dynamic import the canvas with `{ ssr: false }`.
- **drei helper not affecting camera/controls** — missing `makeDefault`.

## Integration Notes
- **Next.js (App Router)**: `'use client'` + `dynamic(() => import('./Scene'), { ssr: false })`.
- **Vite**: works out of the box; ensure DRACO/KTX2 decoder assets are served statically.
- **Testing**: `@react-three/test-renderer` renders the scene graph headless for assertions.

## Best For / Avoid For
`react-apps`, `interactive-3d`, `product-configurators`, `3d-portfolios`, `data-viz-in-react` — choose R3F when your app is already React and you want the scene graph to live in components/state.
Avoid for: non-React projects (use three.js directly), no-code scenes (Spline), or ultra-minimal one-off demos where a bundler + React is overkill.

## See Also
- `three_js.md` — the underlying API; every R3F element maps to it
- `webgl.md` — the raw layer beneath three.js
- `spline.md`, `playcanvas.md`, `verge3d.md` — editor/engine alternatives
- `../use-case/3d-graphics.md` — choosing among 3D solutions
