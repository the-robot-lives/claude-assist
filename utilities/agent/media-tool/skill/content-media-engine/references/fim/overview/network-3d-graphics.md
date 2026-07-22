# Network & Graph Visualization + 3D Engines / WebGL

This category spans two related families of spatial rendering: node-edge graph visualization (force/constraint layouts and network analysis) and 3D/WebGL rendering engines (real-time scenes, globes, scientific volumes, and pseudo-3D illustration). Most solutions emit code — JavaScript for the browser (Canvas/SVG/WebGL) or Python/R/Java for an analysis runtime — that a library then turns into an interactive canvas, a plotted image, or a streamed render.

## Solutions

### Network & Graph Visualization

#### Cytoscape.js
Professional-grade graph-theory library rendering interactive node-edge graphs (Canvas 2D, WebGL fallback) with a deep algorithm set and 40+ layout/interaction extensions. The LLM emits JS/TS building `elements` + `style` + `layout`, mounted via npm or CDN. Pick it for full-featured network apps (social/knowledge/dependency graphs) where algorithms and extensibility matter more than raw node count. [Detail](network-3d-graphics/cytoscape_js.md)

### Vis.js Network
Browser network library with built-in physics and interaction handling out of the box. The LLM emits `nodes`/`edges` arrays and a `new Network(container, data, options)`. Reach for it for quick mid-size interactive graphs (org charts, dependency/workflow diagrams); it degrades past ~1000 nodes, where Sigma.js is the better call. [Detail](network-3d-graphics/vis_js.md)

### Sigma.js
WebGL-powered renderer optimized for large networks (10K+ nodes) backed by the `graphology` data model. The LLM builds a `graphology` graph and a `new Sigma(graph, container, options)`. Choose it when scale and smooth pan/zoom dominate over algorithm/extension breadth. [Detail](network-3d-graphics/sigma_js.md)

### D3 Force
Physics-based force-simulation module for D3.js that positions nodes and leaves rendering to D3's SVG selections. The LLM emits a `d3.forceSimulation` with link/charge/center/collision forces and a `tick` handler. Pick it for fully custom, animated network visualizations when you want fine control and don't mind wiring rendering by hand. [Detail](network-3d-graphics/d3-force.md)

### Cola.js (WebCola)
Constraint-based layout library that adds a formal solver (alignment, grouping, overlap avoidance) on top of D3 rendering. The LLM emits `nodes`/`links`/`constraints` and a `cola.d3adaptor(d3)` layout. Reach for it over d3-force when the diagram has hard positioning rules (UML, hierarchical/constrained layouts). [Detail](network-3d-graphics/cola_js.md)

### Springy.js
Tiny (~8KB) zero-dependency force-directed layout with a simple Canvas renderer hook. The LLM emits a `Springy.Graph`, a `ForceDirected` layout, and a `Renderer` with draw callbacks. Pick it only when bundle size and simplicity outweigh features (simple/embedded/educational diagrams). [Detail](network-3d-graphics/springy_js.md)

### NetworkX
Comprehensive Python library for creating, manipulating, and analyzing networks, with matplotlib visualization. The LLM emits Python building an `nx.Graph()`, running algorithms, and drawing via `nx.draw`. Choose it for approachable Python-based analysis and data-science workflows; use igraph when large-graph performance matters. [Detail](network-3d-graphics/networkx.md)

### igraph
C-backed network-analysis library with Python/R/C bindings and Cairo-rendered static plots. The LLM emits (typically) Python building `ig.Graph()`, running analysis, and rendering via `ig.plot()`. Reach for it over NetworkX when performance, algorithm depth, and memory efficiency on large graphs are the priority. [Detail](network-3d-graphics/igraph.md)

### Gephi
GUI-first desktop application (plus a Java toolkit) for interactive exploration and analytics of networks. The LLM emits Java Toolkit code building a `GraphModel` and running a layout algorithm. Choose it when human-driven visual exploration and advanced statistics matter more than embedding in a code pipeline. [Detail](network-3d-graphics/gephi.md)

### 3D Engines / WebGL

### Three.js
The default general-purpose JS 3D library with a scene-graph API over WebGL/WebGL2/WebGPU and a deep material/lighting system. The LLM emits scene-graph JS (scene, camera, mesh, renderer, animation loop). Reach for it as the flexible baseline for 3D data viz, models, and scenes; heavier than needed for simple 2D work. [Detail](network-3d-graphics/three_js.md)

### Babylon.js
Batteries-included, game-engine-style 3D framework (PBR, physics, particles, audio, WebXR) built in TypeScript and Microsoft-backed. The LLM emits an `Engine` + `Scene` on a canvas via npm or CDN. Pick it over Three.js when you want a full engine's built-in systems rather than a lean, general-purpose toolkit. [Detail](network-3d-graphics/babylon_js.md)

### PlayCanvas
Lightweight, mobile-friendly 3D engine with an entity-component API and a cloud-based collaborative editor. The LLM emits a `pc.Application` with entity/component setup and an update loop. Choose it (vs. Babylon/Three.js) when mobile performance and a collaborative editor workflow matter most. [Detail](network-3d-graphics/playcanvas.md)

### React Three Fiber
React components for Three.js, expressing scene graphs declaratively as JSX (`<Canvas>`, Drei helpers). Same WebGL output as Three.js through React's model, installed via `@react-three/fiber` + `@react-three/drei`. Pick it when the 3D scene lives inside a React app and you want declarative components and hooks. [Detail](network-3d-graphics/react-three-fiber.md)

### A-Frame
WebXR-first framework for VR/AR using declarative HTML markup (`<a-scene>`, entity-component-system) on top of Three.js. The LLM emits HTML entities/components, served from a dev server. Reach for it for cross-platform immersive content and rapid VR/AR prototyping with HTML-familiar syntax. [Detail](network-3d-graphics/a-frame.md)

### X3DOM
Plugin-free declarative 3D embedded in HTML following the X3D/VRML scene-graph standard. The LLM emits `<x3d><scene>` markup with shapes and transforms, rendered to WebGL by `x3dom.js`. Choose it (vs. A-Frame) for standards-based, CAD-lineage declarative 3D rather than WebXR-focused ECS. [Detail](network-3d-graphics/x3dom.md)

### Verge3D
Artist-oriented toolkit that turns Blender/3ds Max/Maya glTF exports into interactive WebGL apps with no-code "Puzzles" logic (license-gated). The LLM emits a `v3d.App` loading glTF scenes with event wiring. Pick it when content is DCC-authored and app logic should be built visually rather than in code. [Detail](network-3d-graphics/verge3d.md)

### Zdog
Pseudo-3D engine for canvas/SVG rendering round, flat-shaded 3D-look illustrations (no true perspective). The LLM emits a `Zdog.Illustration` with primitive shapes and a rotate/render loop. Reach for it for stylized icons, logos, and loading animations — aesthetic simplicity, not fidelity. [Detail](network-3d-graphics/zdog.md)

### WebGL
The low-level native browser API (OpenGL ES shaders) that the higher-level engines build on — no install. The LLM emits raw WebGL JS: GLSL shaders, compiled programs, and typed-array buffers. Drop to it only when you need direct GPU control (custom shaders, instancing, transform feedback) that frameworks don't expose. [Detail](network-3d-graphics/webgl.md)

### Cesium.js
Purpose-built library for 3D globes and maps with accurate terrain, imagery layers, time-dynamic data, and 3D Tiles. The LLM emits a `Cesium.Viewer` with camera flights and entities. Choose it (vs. general 3D engines) whenever the visualization is fundamentally georeferenced and global. [Detail](network-3d-graphics/cesium_js.md)

### VTK.js
Kitware/VTK-lineage scientific-visualization library for browser-side medical/engineering data (GPU volume rendering, DICOM, slice views). The LLM emits module imports, a render window, a data reader, and a volume actor. Reach for it for client-side scientific/volumetric rendering; use ParaView Web when data is too large to render in the browser. [Detail](network-3d-graphics/vtk_js.md)

### ParaView Web
Server-side scientific-visualization platform that streams renders of massive datasets to a browser client over WSLink. The LLM emits both a Python/ParaView server pipeline and a vtk.js/React client. Choose it over VTK.js when datasets exceed client-side capacity and you need server rendering and collaboration. [Detail](network-3d-graphics/paraview-web.md)

## See also
- Per-solution detail files: `network-3d-graphics/{solution}.md`
