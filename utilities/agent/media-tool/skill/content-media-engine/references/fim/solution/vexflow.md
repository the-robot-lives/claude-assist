# VexFlow — Programmatic Music Notation Rendering (JS/TS)

VexFlow is a JavaScript/TypeScript engine that renders standard music notation and guitar
tablature to SVG or Canvas. Unlike text formats (ABC, MusicXML), you build the score
imperatively from note, stave, voice, and formatter objects — giving pixel-level control at
the cost of manual layout. It is the rendering core beneath OpenSheetMusicDisplay, music21j,
and many web notation editors.

**Current Version**: 4.2.x (ESM, TypeScript-first)  **License**: MIT
**Bundle**: ~450KB min (SVG-only builds smaller)  **Runtime**: Browser (SVG/Canvas); Node via `canvas`/`jsdom`

## Official Resources & Documentation
- Site & tutorial: https://vexflow.com/
- GitHub: https://github.com/0xfe/vexflow
- npm: https://www.npmjs.com/package/vexflow
- API/Guides: https://github.com/0xfe/vexflow/wiki
- EasyScore tutorial: https://github.com/0xfe/vexflow/wiki/Using-EasyScore
- Playground: https://vexflow.com/build/

## Installation & Setup

### Package manager
```bash
npm install vexflow
```

### ES module import (v4)
```javascript
import { Renderer, Stave, StaveNote, Voice, Formatter, Beam, Accidental } from 'vexflow';
```

### Factory / EasyScore (higher level)
```javascript
import { Factory } from 'vexflow';
```

### CDN (browser)
```html
<script src="https://cdn.jsdelivr.net/npm/vexflow@4/build/cjs/vexflow.js"></script>
<script>const { Renderer, Stave, StaveNote, Voice, Formatter } = Vex.Flow;</script>
```

## Core API Reference

VexFlow's low-level pipeline is: **Renderer → Context → Stave(s) → Tickables (notes) →
Voice(s) → Formatter → draw**. The Formatter computes horizontal positions; you must call
it or notes stack at x=0.

### Renderer & context
```javascript
const div = document.getElementById('output');
const renderer = new Renderer(div, Renderer.Backends.SVG);  // or .CANVAS
renderer.resize(500, 200);
const context = renderer.getContext();
context.setFont('Arial', 10);
```

### Stave — the staff lines + clef/key/time
```javascript
const stave = new Stave(10, 40, 400);      // x, y, width
stave.addClef('treble')                    // treble|bass|alto|tenor|percussion
     .addKeySignature('G')                 // key signature
     .addTimeSignature('4/4');
stave.setContext(context).draw();
```

### StaveNote — pitched notes, chords, rests
`keys` are `"letter/octave"` strings; a chord lists several. `duration` uses the codes
`w h q 8 16 32` (whole/half/quarter/…) plus `d` for dotted and `r` for rest.
```javascript
const notes = [
  new StaveNote({ keys: ['c/4'], duration: 'q' }),
  new StaveNote({ keys: ['e/4', 'g/4', 'c/5'], duration: 'q' }), // chord
  new StaveNote({ keys: ['b/4'], duration: 'qd' }),              // dotted quarter
  new StaveNote({ keys: ['b/4'], duration: 'qr' }),              // quarter rest
];
```

### Accidentals & dots (Modifiers)
Accidentals are NOT inferred from the key signature — attach them explicitly.
```javascript
import { Accidental, Dot } from 'vexflow';
const n = new StaveNote({ keys: ['c#/4', 'e/4'], duration: 'q' });
n.addModifier(new Accidental('#'), 0);   // sharp on index-0 key (c#)
Dot.buildAndAttach([n], { all: true });  // dot every notehead
```

### Voice & Formatter
A Voice declares a metrical capacity; tickables must fill it (or set strict mode off).
```javascript
const voice = new Voice({ num_beats: 4, beat_value: 4 });
voice.addTickables(notes);
new Formatter().joinVoices([voice]).format([voice], 350); // 350 = width to fit into
voice.draw(context, stave);
```
Loosen strictness for partial bars:
```javascript
const v = new Voice({ num_beats: 4, beat_value: 4 }).setStrict(false);
```

### Beams & ties
```javascript
import { Beam, StaveTie } from 'vexflow';
const beams = Beam.generateBeams(eighthNotes);   // auto-group beamable runs
beams.forEach(b => b.setContext(context).draw()); // draw AFTER voice.draw

const tie = new StaveTie({ first_note: n1, last_note: n2, first_indices: [0], last_indices: [0] });
tie.setContext(context).draw();
```

### Stem direction, articulations, ornaments
```javascript
import { Articulation, Ornament } from 'vexflow';
note.setStemDirection(-1);                       // 1 up, -1 down
note.addModifier(new Articulation('a.').setPosition(3)); // staccato below
note.addModifier(new Articulation('a>').setPosition(3)); // accent
note.addModifier(new Ornament('mordent'));
```

### EasyScore — concise note entry
Skips most of the boilerplate; a compact grammar produces tickables.
```javascript
const vf = new Factory({ renderer: { elementId: 'output', width: 500, height: 200 } });
const score = vf.EasyScore();
const system = vf.System();
system.addStave({
  voices: [ score.voice(score.notes('C4/q, E4, G4, C5', { stem: 'up' })) ]
}).addClef('treble').addTimeSignature('4/4');
vf.draw();
```
EasyScore grammar: `C4/q` (pitch/duration), `(C4 E4 G4)/h` (chord), `C4/8, D4, E4` (comma
list, duration sticky), `C#5/q[id="x"]`, `B4/qr` (rest).

## Supported Notation Types
- Standard staff notation (treble/bass/alto/tenor/percussion clefs)
- Chords, multi-voice staves, grand staff, key/time signatures
- Guitar/bass **tablature** (`TabStave`, `TabNote`) with bends, slides, vibrato
- Beams, tuplets, ties, slurs, grace notes, cross-staff beaming
- Dynamics, articulations, ornaments, fingerings, annotations
- Percussion notation, repeat/volta bar types, multi-measure rests

## How-To (worked recipes)

### How to color notes and stems
Set the SVG style on the note (or per-notehead via `setKeyStyle`).
```javascript
const n = new StaveNote({ keys: ['c/4', 'e/4'], duration: 'q' });
n.setStyle({ fillStyle: '#c0392b', strokeStyle: '#c0392b' }); // whole note red
n.setKeyStyle(1, { fillStyle: '#2980b9' });                   // just e/4 blue
```

### How to render guitar tablature
```javascript
import { TabStave, TabNote } from 'vexflow';
const tabStave = new TabStave(10, 40, 400).addClef('tab').setContext(context).draw();
const tabNotes = [
  new TabNote({ positions: [{ str: 3, fret: 5 }], duration: 'q' }),
  new TabNote({ positions: [{ str: 2, fret: 3 }, { str: 3, fret: 5 }], duration: 'q' }),
];
Formatter.FormatAndDraw(context, tabStave, tabNotes);
```

### How to draw a beamed group of eighth notes
```javascript
const eighths = ['c/4','d/4','e/4','f/4'].map(k =>
  new StaveNote({ keys: [k], duration: '8' }));
const voice = new Voice({ num_beats: 2, beat_value: 4 }).addTickables(eighths);
const beams = Beam.generateBeams(eighths);
new Formatter().joinVoices([voice]).format([voice], 300);
voice.draw(context, stave);
beams.forEach(b => b.setContext(context).draw());  // beams drawn last
```

### How to create a tuplet (triplet)
```javascript
import { Tuplet } from 'vexflow';
const triplet = ['c/4','d/4','e/4'].map(k => new StaveNote({ keys:[k], duration:'8' }));
const voice = new Voice({ num_beats: 1, beat_value: 4 }).addTickables(triplet);
const tuplet = new Tuplet(triplet, { num_notes: 3, notes_occupied: 2 });
new Formatter().joinVoices([voice]).format([voice], 200);
voice.draw(context, stave);
tuplet.setContext(context).draw();
```

## Do's and Don'ts

### ✅ Do
- Always run the `Formatter` (`.format()` or `Formatter.FormatAndDraw`) — without it notes overlap at x=0.
- Attach accidentals explicitly with `Accidental`; VexFlow does not derive them from the key signature.
- Draw beams, ties, and tuplets *after* `voice.draw()` — they read the notes' final positions.
- Use `Formatter.FormatAndDraw(ctx, stave, notes)` for quick single-voice output.
- Prefer EasyScore/Factory for hand-authored scores; drop to the low-level API for generated or unusual layouts.

### ❌ Don't
- Don't leave a Voice under-filled in strict mode — it throws; call `.setStrict(false)` for partial bars.
- Don't reuse one `StaveNote` object across multiple voices/staves — build fresh instances.
- Don't forget `renderer.resize()` — an unsized SVG clips or renders blank.
- Don't expect audio — VexFlow renders only; pair with [tone_js](tone_js.md) or the [web-audio-api](web-audio-api.md) for playback.
- Don't mix VexFlow major versions' import styles — v4 is ESM (`import { … } from 'vexflow'`), older docs show `Vex.Flow.*`.

## Styling, Theming & Customization
- **Per-object style**: `.setStyle({ fillStyle, strokeStyle, lineWidth })` on notes, staves, modifiers.
- **Stave line color**: `stave.setStyle({ strokeStyle: '#888' })`.
- **Fonts**: `context.setFont(family, size)`; music glyphs use the bundled Bravura-derived font. v4 supports pluggable SMuFL music fonts (Bravura, Petaluma, Gonville).
- **Backgrounds**: style the container `<div>` / canvas via CSS — VexFlow draws transparent.
- **Scale**: `context.scale(sx, sy)` zooms all subsequent drawing.

## Advanced Features
- **Multiple voices per stave**: `Formatter.joinVoices([v1, v2])` aligns them rhythmically; set opposing stem directions.
- **Cross-staff beaming** for piano music via `StaveNote.setStave()`.
- **System/Factory API** manages multi-stave systems, connectors (braces/brackets), and page layout for you.
- **Bends & slides** in tablature: `TabNote.addModifier(new Bend('full'))`.
- **Node/SSR**: render with the `canvas` npm package or `jsdom` to produce SVG strings server-side.

## Common Pitfalls & Troubleshooting
- **Notes overlap / all at left edge** → Formatter not called, or `.format([voice], width)` width too small.
- **Blank output** → missing `renderer.resize()`, or drawing before `setContext(context)`.
- **Accidental missing** → must add `Accidental` modifier manually.
- **Beams/ties misplaced** → drawn before `voice.draw()`; reorder so they draw last.
- **"BadArguments: Too many ticks"** → Voice capacity smaller than note durations; fix `num_beats`/`beat_value` or use tuplets.
- **Version drift** → v3→v4 renamed the entry point to ESM `vexflow`; `require('vexflow').Flow` for CJS.

## Integration Notes
- **OSMD** wraps VexFlow to render MusicXML — use [osmd](osmd.md) if you have MusicXML rather than hand-built notes.
- **music21j** uses VexFlow for its `.show()` rendering.
- React/Vue: build in a `useEffect`/`mounted` hook after the container exists; clear `innerHTML` before re-render.

## Best For / Avoid For
`interactive-editors`, `dynamic-generation`, `education-apps`, `tablature`, `custom-layout`,
`real-time` — choose VexFlow when you need programmatic, client-side notation with fine control.
Avoid for: rendering existing MusicXML (use [osmd](osmd.md)), publication engraving (use
[lilypond](lilypond.md)), or simple folk tunes where [abcjs](abcjs.md) is far less code.

## See Also
- [abcjs](abcjs.md) — text-notation renderer with built-in MIDI
- [osmd](osmd.md) — MusicXML → VexFlow rendering
- [music21j](music21j.md) — analysis toolkit that renders via VexFlow
- [alphatab](alphatab.md) — tablature + playback
- [tone_js](tone_js.md) / [web-audio-api](web-audio-api.md) — add playback
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
