# Flat API

## What
Flat API is a cloud-based (REST) music-notation service for creating, editing, and managing musical scores programmatically, with real-time collaboration and advanced export. It is a SaaS platform consumed over HTTP (JSON, MusicXML, MIDI) from web, mobile, and desktop apps. Commercial with a limited free tier.

## How
- **LLM emits:** REST API requests (JSON payloads) and/or MusicXML score bodies — e.g. score-create calls carrying `{ title, musicXML, privacy, collaboration }`.
- **Render/execute step:** authenticate via OAuth2 (client_id/secret, redirect_uri, scopes like `scores.read scores.write scores.social`), then call the REST endpoints. Install the client with `npm install flat-api`. The service handles rendering and export server-side.
- **Final artifact:** exported scores in PDF, MIDI, MP3, MusicXML, or PNG (with quality options), plus an embeddable responsive score-viewer widget with playback. Note the export artifact can be audio (MIDI/MP3) as well as visual (PDF/PNG).

## Why
- **Reach for it when:** you need real-time multi-user collaboration, full revision history (branching/merging), and professional multi-format exports without building a rendering pipeline — music-education platforms, collaborative composition, score-sharing apps, and institutional content management. Rich API with webhooks, real-time events, and batch operations.
- **Limitations:** subscription required for advanced features; rate limits (1000–10000 req/hr by plan); no offline editing (internet dependency); per-score file-size caps; limited import formats (mainly MusicXML/MIDI/native); some regional restrictions.
- **Relative to siblings:** Flat API is the managed cloud/collaboration option. Where Noteflight API is the other commercial embedded-editor SaaS, Flat leans on a RESTful, webhook-driven backend for programmatic score management; contrast both with client-side renderers (VexFlow/OSMD) that draw scores locally but provide no cloud storage, collaboration, or server-side export.

## Source
- Solution reference: `fim/solution/flat-api.md`
