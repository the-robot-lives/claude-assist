# ParaView Web

## What
ParaView Web is a remote scientific-visualization platform for server-side rendering, collaborative analysis, and exploration of massive datasets through the browser. Rendering happens on a server (headless/GPU ParaView) and is streamed to a web client over the WSLink protocol. Primary consumers are a Python/ParaView server plus a browser client.

## How
- The LLM emits both server-side Python (a ParaView/WSLink application driving `paraview` visualization pipelines) and a JavaScript/React client that connects over WSLink and renders via `vtk.js`.
- Turned into a viewable artifact by installing ParaView on the server (binary download + `pip install paraview twisted autobahn wslink numpy scipy vtk`) and the client stack (`paraviewweb`, `wslink`, `vtk.js`, React, built with webpack) — often deployed via the Kitware Docker image; the server renders and streams frames/geometry to the browser.
- Typical final artifact: a browser-delivered interactive scientific visualization backed by server-side rendering.

## Why
- Reach for ParaView Web when datasets are too large to render client-side and you need server-side rendering, collaboration, and production deployment for scientific/engineering visualization (16GB+ RAM and OpenGL/GPU recommended on the server).
- Tradeoffs: it is a heavyweight, server-plus-client deployment (Python environment, WSLink, Docker) rather than a drop-in browser library.
- Versus [[vtk_js]] — both are Kitware/VTK-lineage, but VTK.js renders entirely in the browser for smaller data, while ParaView Web offloads massive-dataset rendering to a server.

## Source
- Solution reference: `fim/solution/paraview-web.md`
