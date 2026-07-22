# Gephi

## What
Gephi is an open-source desktop application for interactive visualization and exploration of networks and complex systems. It offers a GUI for network exploration plus a Java "Gephi Toolkit" for programmatic use. Primary consumer is the desktop app (or a JVM runtime via the toolkit) — not the browser.

## How
- The LLM emits Java that uses the Gephi Toolkit API: create a project/workspace, get the `GraphModel`, build nodes/edges via `graphModel.factory()`, and run a layout algorithm (e.g. `YifanHuLayout` with `StepDisplacement`) in an `initAlgo()`/`goAlgo()` loop.
- Turned into a viewable artifact either interactively in the Gephi desktop app (downloaded from gephi.org) or by embedding the toolkit as a Maven dependency (`org.gephi:gephi-toolkit`) in a Java program.
- Typical final artifact: an interactive on-screen network exploration, or exported image/graph files.

## Why
- Reach for Gephi when the goal is human-driven exploration and analytics of a network: research visualization, social network analysis, and large graph analytics, backed by real-time visualization, advanced statistics, a plugin ecosystem, and broad import/export formats.
- Limitations: it is a desktop application, memory intensive, and not web-deployable.
- Versus code libraries like [[networkx]] or [[igraph]] — those are scripting-first analysis libraries, while Gephi is a GUI-first exploration tool; use Gephi when interactive exploration matters more than embedding in a pipeline.

## Source
- Solution reference: `fim/solution/gephi.md`
