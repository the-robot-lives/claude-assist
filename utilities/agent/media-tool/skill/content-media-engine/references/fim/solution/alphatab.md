# alphaTab — Guitar Tablature & Notation with Playback

alphaTab is a cross-platform music-notation engine specializing in **guitar/bass tablature**
alongside standard notation, with built-in audio synthesis (a bundled SoundFont + sequencer).
It reads Guitar Pro files (GP3–GP7/`.gp`), MusicXML, and its own text format **alphaTex**,
renders to SVG/Canvas, and plays back with a synchronized cursor. It runs in the browser,
.NET, and (via the same core) Android.

**Current Version**: 1.5.x (`@coderline/alphatab`)  **License**: MPL-2.0 (LGPL for some assets)
**Runtime**: Browser (Web Worker + WebAudio), .NET, Android/Kotlin  **Assets**: SoundFont (~1–5MB), music font

## Official Resources & Documentation
- Site: https://www.alphatab.net/
- Docs: https://www.alphatab.net/docs/
- GitHub: https://github.com/CoderLine/alphaTab
- npm: https://www.npmjs.com/package/@coderline/alphatab
- alphaTex reference: https://www.alphatab.net/docs/alphatex/introduction
- API reference: https://www.alphatab.net/docs/reference/api

## Installation & Setup

### Package manager
```bash
npm install @coderline/alphatab
```

### CDN + stylesheet
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/alphaTab.min.css">
<script src="https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/alphaTab.min.js"></script>
<div id="alphatab"></div>
```

### ES module import
```javascript
import * as alphaTab from '@coderline/alphatab';
```

## Core API Reference

The entry point is `AlphaTabApi`, constructed on a container element with a settings
object. It manages parsing, layout, rendering, and (optionally) a player. Fonts and
SoundFonts load asynchronously; listen for the render/ready events.

### Initialize with a file + player
```javascript
const el = document.getElementById('alphatab');
const api = new alphaTab.AlphaTabApi(el, {
  file: 'song.gp',                       // GP/MusicXML URL, or omit and call api.load(...)
  core: { fontDirectory: '/font/' },     // path to the bundled Bravura font files
  player: {
    enablePlayer: true,
    enableCursor: true,
    enableUserInteraction: true,
    soundFont: 'https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/soundfont/sonivox.sf2',
    scrollElement: el,                   // element that scrolls to follow the cursor
  },
  display: {
    layoutMode: alphaTab.LayoutMode.Page, // Page | Horizontal
    staveProfile: alphaTab.StaveProfile.ScoreTab, // Score | Tab | ScoreTab
    scale: 1.0,
  },
});
```

### Loading scores
```javascript
api.load('another.gp');                          // by URL
const buf = await (await fetch('song.gp5')).arrayBuffer();
api.load(new Uint8Array(buf));                   // binary GP/MXL
api.tex(`\\title "Riff"\n.\n3.3.4 3.3.8 5.3.8`); // inline alphaTex
```

### Playback control
```javascript
api.play();
api.pause();
api.playPause();
api.stop();
api.playbackSpeed = 0.75;       // 75% tempo (practice)
api.masterVolume = 0.8;         // 0..1
api.metronomeVolume = 1;        // click track on
api.countInVolume = 1;          // count-in
api.isLooping = true;
```

### Track selection (multi-instrument scores)
```javascript
api.renderTracks([ api.score.tracks[0] ]);   // show only track 0
api.changeTrackMute([api.score.tracks[1]], true);
api.changeTrackSolo([api.score.tracks[0]], true);
api.changeTrackVolume([api.score.tracks[0]], 0.9);
```

### Events
```javascript
api.scoreLoaded.on(score => console.log('Loaded:', score.title));
api.renderFinished.on(() => console.log('Rendered'));
api.playerStateChanged.on(e => console.log('state', e.state)); // Playing/Paused
api.playerPositionChanged.on(e => console.log(e.currentTime, e.endTime));
api.error.on(err => console.error(err));
```

## alphaTex — text notation format
alphaTex is alphaTab's human-writable source. Notes are `fret.string.duration`; metadata
uses `\`-prefixed directives terminated by a `.` line before the music.
```text
\title "Example"
\tempo 120
\instrument 25
.
:4 3.3 5.3 7.3 |    // quarter notes: fret.string on 3rd string
:8 0.4 2.4 3.4 0.4 |
(0.1 1.2 0.3).4     // a chord as a quarter note
```

## Supported Formats & Output
- **Input**: Guitar Pro `.gp3 .gp4 .gp5 .gpx .gp`, MusicXML/`.mxl`, alphaTex, Capella (partial).
- **Output**: SVG or HTML5 Canvas rendering; WebAudio synthesized playback via SoundFont2.
- **Notation**: standard staff, tablature, bends, slides, hammer-ons/pull-offs, vibrato,
  palm mute, rhythm slashes, drums, multi-track scores.

## How-To (worked recipes)

### How to theme colors and fonts
alphaTab exposes render styling through settings and CSS. The music font is set by
`fontDirectory`; layout colors via `display.resources`.
```javascript
const api = new alphaTab.AlphaTabApi(el, {
  core: { fontDirectory: '/font/' },
  display: {
    resources: {
      mainGlyphColor: '#1a1a1a',
      staffLineColor: '#888888',
      barSeparatorColor: '#555555',
      secondaryGlyphColor: '#c0392b',
      scoreInfoColor: '#333333',        // title/subtitle text
    },
  },
});
```

### How to build a practice loop at reduced tempo
```javascript
api.isLooping = true;
api.playbackSpeed = 0.6;      // 60% speed
api.metronomeVolume = 1;      // click for timing
// Select a range to loop via api.playbackRange = { startTick, endTick }
api.play();
```

### How to render only tablature (no standard staff)
```javascript
const api = new alphaTab.AlphaTabApi(el, {
  file: 'song.gp',
  display: { staveProfile: alphaTab.StaveProfile.Tab },
});
```

### How to load a Guitar Pro file from a user upload
```javascript
input.addEventListener('change', async (e) => {
  const buf = await e.target.files[0].arrayBuffer();
  api.load(new Uint8Array(buf));   // binary path handles GP + MXL
});
```

## Do's and Don'ts

### ✅ Do
- Serve the bundled music font (`core.fontDirectory`) — missing it renders empty/□ glyphs.
- Load a SoundFont before expecting audio; playback is silent until it and WebAudio are ready.
- Resume WebAudio inside a user gesture (browsers block autoplay) — call `api.play()` from a click.
- Use `staveProfile` to control Score/Tab/ScoreTab display rather than post-processing.
- Load binary GP/MXL as `Uint8Array`; use `api.tex()` for inline alphaTex.

### ❌ Don't
- Don't point `soundFont` at a missing/blocked URL — playback fails silently.
- Don't render huge multi-track scores fully when you only need one track — call `renderTracks`.
- Don't assume MusicXML fidelity equals Guitar Pro — GP is alphaTab's native, richest path.
- Don't forget the CSS file — layout/scroll behavior depends on it.
- Don't block the main thread parsing large files — alphaTab uses a Web Worker; keep it enabled.

## Styling, Theming & Customization
- **Colors**: `display.resources.*` (glyphs, staff lines, bar separators, text, cursor).
- **Music font**: SMuFL-compatible (Bravura by default); set `core.fontDirectory`.
- **Scale/zoom**: `display.scale`.
- **Layout**: `LayoutMode.Page` (wrapping pages) vs `LayoutMode.Horizontal` (single scrollable line).
- **Cursor styling**: CSS classes `.at-cursor-bar`, `.at-cursor-beat`, `.at-highlight`.

## Advanced Features
- **Multi-track mixing**: per-track mute/solo/volume, live during playback.
- **Playback range looping** for practice; adjustable `playbackSpeed` without pitch change.
- **Synchronized cursor** that scrolls the score and highlights the active beat.
- **alphaTex** for quick authoring and generation without binary tooling.
- **Cross-platform core**: the same engine ships for .NET (WPF/WinForms) and Android.
- **Export**: render to SVG strings; capture canvas frames for images.

## Common Pitfalls & Troubleshooting
- **Empty/□ glyphs** → `fontDirectory` wrong or font files not served.
- **No sound** → SoundFont not loaded, WebAudio suspended (needs user gesture), or `enablePlayer:false`.
- **Cursor doesn't scroll** → set `player.scrollElement` to the scrolling container.
- **CORS on file/soundFont** → serve same-origin or set CORS headers.
- **Blank until interaction** → normal; browsers require a gesture to start audio and sometimes render.
- **Wrong track shown** → default renders all; call `renderTracks([...])` for a subset.

## Integration Notes
- **React/Vue**: construct `AlphaTabApi` in a mount hook after the container exists; destroy via `api.destroy()` on unmount.
- **Self-hosting assets**: copy `dist/font/` and `dist/soundfont/` into your public dir and point settings at them (avoids CDN/CORS surprises).
- Complements [osmd](osmd.md): OSMD for pure MusicXML display, alphaTab when tab + playback matter.

## Best For / Avoid For
`guitar-tab`, `guitar-pro-viewer`, `playback`, `practice-tools`, `band-notation`,
`multi-track` — choose alphaTab when tablature and synchronized audio are central.
Avoid for: pure classical staff engraving (use [lilypond](lilypond.md)/[osmd](osmd.md)),
lightweight folk notation (use [abcjs](abcjs.md)), or building notation object-by-object
(use [vexflow](vexflow.md)).

## See Also
- [musicxml](musicxml.md) — alternate input format alphaTab reads
- [osmd](osmd.md) — MusicXML-first renderer without tab focus
- [vexflow](vexflow.md) — low-level programmatic notation
- [tone_js](tone_js.md) / [web-audio-api](web-audio-api.md) — audio internals alphaTab abstracts
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
