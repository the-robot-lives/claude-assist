# React Three Fiber

## What
React Three Fiber (R3F) provides React components for Three.js, expressing 3D scene graphs declaratively as JSX. It renders the same real-time WebGL output as Three.js but through React's component model. Primary consumer is browser JavaScript within a React app.

## How
- The LLM emits JSX that wraps the scene in a `<Canvas>` (with `camera` props) and composes lights, meshes, geometries/materials, and helpers — often using `@react-three/drei` primitives like `<Box>`, `<OrbitControls>`, and inline `<mesh>`/`<sphereGeometry>`/`<meshStandardMaterial>`.
- Turned into a viewable artifact via `npm install three @react-three/fiber @react-three/drei`; the `<Canvas>` mounts a Three.js renderer into the React tree. Physics via `@react-three/cannon`/Rapier and post-processing are available.
- Typical final artifact: an interactive WebGL canvas embedded in a React application.

## Why
- Reach for React Three Fiber when the 3D scene lives inside a React app and you want declarative components, hooks-driven state, and the Drei helper library rather than imperative Three.js setup. Best practices from the source: use `useFrame` for animation, Suspense for loading, memoize expensive computations, and instances for repeated geometry.
- Tradeoffs: it inherits Three.js's capabilities and its complexity, and adds a React dependency and reconciler layer.
- Versus [[three_js]] — same underlying engine and output; R3F is the React-native, declarative way to drive it.

## Source
- Solution reference: `fim/solution/react-three-fiber.md`
