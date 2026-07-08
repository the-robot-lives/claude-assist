# OpenSheetMusicDisplay (OSMD) — MusicXML Rendering in the Browser

OpenSheetMusicDisplay is a TypeScript/JavaScript library that renders **MusicXML** (and
compressed `.mxl`) scores to SVG or Canvas in the browser, using VexFlow underneath but
adding a full automatic layout engine. You give it a MusicXML document; it handles line
breaking, spacing, beaming, and formatting. It also exposes a cursor for playback
following. It does *not* generate audio — pair it with a synth for sound.

**Current Version**: 1.9.x  **License**: BSD-3-Clause
**Bundle**: ~2–3MB (includes VexFlow + fonts)  **Runtime**: Browser (ES2015+); loads MusicXML strings/URLs

## Official Resources & Documentation
- Site & demo: https://opensheetmusicdisplay.github.io/demo/
- GitHub: https://github.com/opensheetmusicdisplay/opensheetmusicdisplay
- API docs: https://opensheetmusicdisplay.github.io/opensheetmusicdisplay/
- npm: https://www.npmjs.com/package/opensheetmusicdisplay
- Wiki (options reference): https://github.com/opensheetmusicdisplay/opensheetmusicdisplay/wiki

## Installation & Setup

### Package manager
```bash
npm install opensheetmusicdisplay
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay/build/opensheetmusicdisplay.min.js"></script>
<div id="score"></div>
```

### ES module import
```javascript
import { OpenSheetMusicDisplay } from 'opensheetmusicdisplay';
```

## Core API Reference

The lifecycle is: **construct(container, options) → await load(source) → render()**.
`load` accepts a MusicXML string, a URL, a `.mxl` ArrayBuffer, or a parsed Document.
`render` must be called after every `load`, `zoom` change, or resize.

### Construction & options
```javascript
const osmd = new OpenSheetMusicDisplay('score', {
  backend: 'svg',                  // 'svg' (default) or 'canvas'
  autoResize: true,                // re-render on window resize
  drawTitle: true,
  drawSubtitle: true,
  drawComposer: true,
  drawLyricist: false,
  drawPartNames: true,
  drawPartAbbreviations: true,
  drawMeasureNumbers: true,
  drawMeasureNumbersOnlyAtSystemStart: false,
  drawFingerings: true,
  drawSlurs: true,
  pageFormat: 'Endless',           // 'Endless' | 'A4_P' | 'A4_L' | 'Letter_P' | 'Letter_L'
  pageBackgroundColor: '#FFFFFF',
  renderSingleHorizontalStaffline: false,  // one long line, no wraps
});
```

### Loading a score
```javascript
async function show(source) {
  await osmd.load(source);   // MusicXML string | URL | .mxl ArrayBuffer
  osmd.zoom = 0.8;           // set BEFORE render
  await osmd.render();
}
```

### Cursor (playback following / note iteration)
```javascript
osmd.cursor.show();
osmd.cursor.next();          // advance to next note group
osmd.cursor.previous();
osmd.cursor.reset();         // back to start
osmd.cursor.hide();

// Inspect the notes under the cursor:
const notes = osmd.cursor.NotesUnderCursor();       // VexFlow-level notes
const iter  = osmd.cursor.Iterator;                 // MusicSheet iterator
const measureIndex = iter.CurrentMeasureIndex;
const timestamp    = iter.currentTimeStamp.RealValue;
```

### Reading sheet structure
```javascript
const sheet = osmd.Sheet;
sheet.Title.text;                      // title string
sheet.Instruments;                     // parts
sheet.SourceMeasures.length;           // measure count
osmd.GraphicSheet;                     // rendered graphical model (positions)
osmd.Version;                          // library version
```

### Runtime option changes
```javascript
osmd.setOptions({ drawMeasureNumbers: false });
osmd.setLogLevel('warn');              // 'trace'|'debug'|'info'|'warn'|'error'
osmd.clear();                          // wipe rendered content
await osmd.render();                   // re-render after option change
```

## Supported Input & Output
- **Input**: MusicXML 3.x/4.x (`score-partwise` and `score-timewise`), compressed `.mxl`,
  MXL fetched as ArrayBuffer.
- **Output**: SVG (default, DOM-inspectable) or Canvas (raster, faster for very large scores).
- **Notation coverage**: multi-part scores, dynamics, articulations, slurs, ties, tuplets,
  lyrics, chord symbols, repeats/endings, grace notes, fingerings, tablature (partial).

## How-To (worked recipes)

### How to color notes and the score
Two mechanisms: (1) MusicXML `color` attributes on notes (honored per-element), and
(2) OSMD default-color options for global theming.
```javascript
const osmd = new OpenSheetMusicDisplay('score', {
  defaultColorMusic: '#1a1a1a',    // notes/stems/beams
  defaultColorNotehead: '#c0392b', // noteheads only
  defaultColorStem: '#2980b9',
  defaultColorTitle: '#333333',
});
await osmd.load(musicXml);
await osmd.render();

// Recolor a single note after render, then re-render:
osmd.GraphicSheet.MeasureList[0][0].staffEntries[0]
    .graphicalVoiceEntries[0].notes[0].sourceNote.NoteheadColor = '#00A000';
await osmd.render();
```

### How to load a compressed `.mxl` file from a file input
```javascript
fileInput.addEventListener('change', async (e) => {
  const file = e.target.files[0];
  const buffer = await file.arrayBuffer();   // .mxl is a zip — pass the ArrayBuffer
  await osmd.load(buffer);
  await osmd.render();
});
```

### How to drive a playback cursor with audio
```javascript
import * as Tone from 'tone';
const synth = new Tone.PolySynth().toDestination();

async function step() {
  const notes = osmd.cursor.NotesUnderCursor();
  const pitches = notes
    .filter(n => n.sourceNote.Pitch)
    .map(n => n.sourceNote.Pitch.ToStringShortGet ? n.sourceNote.Pitch.ToString() : n.sourceNote.Pitch.toString());
  if (pitches.length) synth.triggerAttackRelease(pitches, '4n');
  osmd.cursor.next();
}
osmd.cursor.show();
setInterval(step, 500);   // naive; real timing should follow note durations
```

### How to render one long horizontal line (no wrapping)
```javascript
const osmd = new OpenSheetMusicDisplay('score', {
  renderSingleHorizontalStaffline: true,
  autoResize: false,
});
await osmd.load(musicXml);
await osmd.render();
```

### How to responsively re-render on container resize
```javascript
const container = document.getElementById('score');
new ResizeObserver(() => { osmd.render(); }).observe(container);
```

## Do's and Don'ts

### ✅ Do
- Always `await osmd.load(...)` before `render()`; both are async.
- Set `zoom` and options *before* calling `render()`; call `render()` again after any change.
- Pass `.mxl` files as an ArrayBuffer, not a string — they are zipped.
- Reuse a single OSMD instance and `clear()` between scores rather than constructing new ones.
- Validate MusicXML with `DOMParser` first to catch malformed input before `load`.

### ❌ Don't
- Don't expect audio — OSMD renders only; wire up [tone_js](tone_js.md)/[web-audio-api](web-audio-api.md).
- Don't feed it ABC or MIDI — OSMD consumes MusicXML/MXL only (convert first).
- Don't forget CORS — loading a MusicXML URL cross-origin needs proper headers or a proxy.
- Don't mutate the graphic model without a follow-up `render()` — changes won't appear.
- Don't render huge orchestral scores with `backend: 'svg'` if performance matters — try `'canvas'`.

## Styling, Theming & Customization
- **Global colors**: `defaultColorMusic`, `defaultColorNotehead`, `defaultColorStem`,
  `defaultColorRest`, `defaultColorTitle`, `pageBackgroundColor`.
- **Fonts**: `defaultFontFamily` (e.g. `'Times New Roman'`); music glyph font selectable
  (Gonville, Bravura, Petaluma) via `setOptions({ drawingParameters, ... })` and the font build.
- **Spacing/compactness**: `drawingParameters: 'compact'` or `'compacttight'` reduces margins.
- **Per-note color** via MusicXML `color="#RRGGBB"` on `<note>`, `<notehead>`, `<stem>`.
- **CSS**: SVG output is fully styleable/inspectable in the DOM; add classes and target them.

## Advanced Features
- **Cursor API** for practice/playback following, note highlighting, and karaoke-style scroll.
- **Transpose** via the `TransposeCalculator` plugin (`osmd.TransposeCalculator = new …`).
- **Selective drawing**: hide/show measure numbers, part names, fingerings at runtime.
- **PDF/PNG export** by serializing the SVG or using the canvas backend + `toDataURL`.
- **Multi-instrument** scores with per-part visibility toggles.

## Common Pitfalls & Troubleshooting
- **Blank render** → forgot `await render()`, or container has zero width/height.
- **`.mxl` fails to load** → passed a string instead of ArrayBuffer.
- **CORS error on URL load** → proxy the file server-side or set `Access-Control-Allow-Origin`.
- **Slow / heavy** → large scores: use `drawingParameters: 'compact'`, `canvas` backend, disable `autoResize`.
- **Cursor pitches undefined** → rests and unpitched percussion have no `Pitch`; filter them.
- **Layout differs from print** → OSMD's engine ≠ Finale/Sibelius; expect reflow, not pixel-identical output.

## Integration Notes
- **React**: construct in `useEffect` once the ref exists; `load`→`render` in a second effect keyed on the MusicXML prop.
- **Audio**: OSMD + Tone.js is the common practice-app stack (cursor drives the synth).
- **Source pipeline**: export MusicXML from MuseScore/Finale/Sibelius or from [music21j](music21j.md)/[lilypond](lilypond.md) (`musicxml`), then feed OSMD.

## Best For / Avoid For
`musicxml-display`, `digital-sheet-music`, `practice-apps`, `education`, `score-following`,
`mobile-readers` — choose OSMD when you already have MusicXML and want automatic layout.
Avoid for: building notation from scratch programmatically (use [vexflow](vexflow.md)),
guitar-tab + playback (use [alphatab](alphatab.md)), or print-grade engraving (use
[lilypond](lilypond.md)).

## See Also
- [musicxml](musicxml.md) — the input format OSMD consumes
- [vexflow](vexflow.md) — the rendering engine underneath OSMD
- [alphatab](alphatab.md) — tab-focused alternative with built-in audio
- [music21j](music21j.md) — produce MusicXML to feed OSMD
- [tone_js](tone_js.md) — add playback to the cursor
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
