# Noteflight API

## What
Noteflight API is a commercial SaaS for embedding a full-featured interactive music-notation editor and playback into an application. It provides notation editing, cloud storage, collaboration, and export. Its consumer is browser JavaScript embedding the hosted editor widget.

## How
- **LLM emits:** Noteflight client-API JavaScript plus MusicXML score data — e.g. `NFClient.init({ container, width, height, viewParams: { scale, role, hidePlaybackControls } })`, then `editor.loadMusicXML(xmlString)`.
- **Render step:** include the Noteflight client script (`nfclient.js`), initialize the embedded editor against a container, and drive it with methods like `editor.getScore()`, `editor.play()/pause()/stop()`, and event listeners (`scoreChanged`). Rendering, editing UI, and playback are hosted by the service.
- **Final artifact:** an embedded interactive notation editor/viewer with playback in the page; exports available as MusicXML, MIDI, PDF, and audio (so the artifact spans an interactive editor, visual score, and audio).

## Why
- **Reach for it when:** you need a complete embedded editor with real-time multi-user editing, built-in cloud score-library management, and educational assignment/assessment features — music-education platforms, online composition courses, collaborative creation apps, and school/university programs.
- **Limitations:** commercial only (no free production tier); internet required (cloud-based); per-user/per-site subscription licensing; limited UI customization (fixed components).
- **Relative to siblings:** Noteflight API is the turnkey embedded-editor SaaS. Flat API is its closest sibling — both are commercial cloud notation platforms with collaboration and export — but Noteflight emphasizes a drop-in full editor widget and education tooling, whereas Flat exposes a more REST/webhook-oriented programmatic surface. Both differ sharply from client-side renderers (VexFlow/OSMD) that draw scores but provide no editor, storage, or collaboration.

## Source
- Solution reference: `fim/solution/noteflight-api.md`
