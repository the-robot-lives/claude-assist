# Spline

## What
A no-code 3D design tool paired with a web runtime: scenes are authored visually in the Spline editor and embedded/controlled at runtime through a JavaScript API. Its consumer is the browser (via a `<canvas>` and the `@splinetool/runtime`), producing interactive 3D web experiences.

## How
- The LLM emits the *integration* code, not the scene itself: `const app = new Application(canvas)` then `app.load('https://prod.spline.design/YOUR_SCENE_ID/scene.splinecode')` — the `.splinecode` asset is exported from the Spline editor.
- Install via `npm install @splinetool/runtime` or a CDN module import; there is also a first-class React wrapper (`@splinetool/react-spline`, `<Spline scene=... onLoad=... />`). After load you access objects (`app.findObjectByName('Cube')`), mutate them, listen for events (`app.addEventListener('mouseDown', ...)`), emit Spline events, and read/write scene variables.
- Typical final artifact: an interactive 3D canvas scene embedded in a page — landing-page 3D elements, product showcases, portfolios.

## Why
- Reach for Spline when you want polished interactive 3D on the web without hand-writing a 3D engine — visual authoring, built-in interactions/states, real-time collaboration, and a runtime that plugs into React/Vue/vanilla JS.
- Limitations: scene creation *requires* the Spline editor (limited programmatic scene generation), advanced features need a subscription, and the community is smaller than traditional 3D libraries.
- Relative to siblings: spline is the no-code, editor-first 3D option in this category — an outlier alongside the code-first 2D/animation libraries. Choose it when design-tool authoring and quick 3D embeds matter more than code-level control over the scene.

## Source
- Solution reference: `fim/solution/spline.md`
