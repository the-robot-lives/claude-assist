# AlphaTab

## What
AlphaTab is a cross-platform music notation and guitar-tablature rendering engine with built-in audio playback. It renders both standard notation and tablature and synthesizes audio from Guitar Pro and MusicXML sources. Primary consumers are browser JavaScript, .NET, and Android.

## How
- **LLM emits:** typically a reference/loader configuration plus score data (Guitar Pro `.gp3`–`.gp7` binary, or MusicXML). AlphaTab is driven by its API rather than a plain-text score format.
- **Render step:** instantiate `new alphaTab.AlphaTabApi(element, { file, player, display })`, pointing `file` at a score and enabling the player with a soundfont (e.g. `sonivox.sf2`). Install via `npm install @coderline/alphatab` or CDN script + stylesheet. Load data at runtime with `api.load(...)` (accepts a `Uint8Array` from a fetched MusicXML/GP file); control playback with `api.playPause()` / `api.stop()`.
- **Final artifact:** rendered standard notation or tablature (page layout, tab stave) plus synthesized audio playback with a cursor — the artifact is both visual and audible.

## Why
- **Reach for it when:** the domain is guitar/bass — Guitar Pro file viewers, tab-sharing platforms, guitar-learning and practice tools, and band notation software. Its standout strength is excellent Guitar Pro format support (GP3–GP7) plus built-in audio synthesis and cross-platform reach.
- **Limitations:** focused on guitar/bass notation; soundfonts are a large download; the API is complex for simple use cases.
- **Relative to siblings:** AlphaTab is the tablature-and-playback specialist. VexFlow can also render tablature but has no built-in audio and is a lower-level general notation API; AlphaTab is the better fit specifically when Guitar Pro files and integrated playback are the point.

## Source
- Solution reference: `fim/solution/alphatab.md`
