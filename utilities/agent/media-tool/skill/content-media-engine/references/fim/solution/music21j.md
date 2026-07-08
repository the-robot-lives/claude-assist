# music21j — Music Analysis & Notation Toolkit (JavaScript)

music21j is the JavaScript port of MIT's music21 Python toolkit for computer-aided
musicology. It models music as a tree of **Stream** objects containing notes, chords, and
other elements, supports key/interval/chord analysis, imports/exports MusicXML and Tiny
Notation, and renders notation to the browser via VexFlow with optional Web Audio playback.
Choose it when you need to *reason about* music (analysis, theory, transformation), not just
draw it.

**Current Version**: 0.16.x  **License**: BSD-3-Clause
**Bundle**: ~1MB (bundles VexFlow)  **Runtime**: Browser (ES modules); Node possible with a DOM shim

## Official Resources & Documentation
- Site: https://web.mit.edu/music21/music21j/
- GitHub: https://github.com/cuthbertLab/music21j
- API docs: https://web.mit.edu/music21/music21j/doc/
- Python music21 (concept parity): https://web.mit.edu/music21/
- npm: https://www.npmjs.com/package/music21j

## Installation & Setup

### Package manager (ESM)
```bash
npm install music21j
```
```javascript
import * as music21 from 'music21j';
```

### CDN (global `music21`)
```html
<script src="https://cdn.jsdelivr.net/npm/music21j@latest/releases/music21.min.js"></script>
```

## Core API Reference

The object model mirrors Python music21: **Note / Rest / Chord** are elements you `append`
to a **Stream** (or `Part` / `Measure` / `Score` subclasses). Streams render via
`appendNewDOM`/`replaceDOM` and can be analyzed with `.analyze(...)`.

### Notes, rests, chords
```javascript
const n = new music21.note.Note('C#4');   // scientific pitch name
n.duration.quarterLength = 2;             // 2 quarters = half note
n.volume.velocity = 90;

const r = new music21.note.Rest();
r.duration.quarterLength = 1;

const c = new music21.chord.Chord(['C4', 'E4', 'G4']);
c.duration.type = 'half';
```

### Pitch, interval, duration
```javascript
const p = new music21.pitch.Pitch('E-4');   // E flat 4 ("-" flat, "#" sharp)
p.diatonicNoteNum; p.frequency; p.midi;      // 64-ish, Hz, MIDI number

const i = new music21.interval.Interval('P5');
const up = i.transposePitch(p);              // transpose by a perfect fifth

const d = new music21.duration.Duration('eighth');
d.dots = 1;                                  // dotted eighth
```

### Streams (containers)
```javascript
const s = new music21.stream.Stream();
s.append(new music21.note.Note('C4'));
s.append(new music21.note.Note('D4'));
s.append(new music21.chord.Chord(['E4','G4']));

const part = new music21.stream.Part();
const measure = new music21.stream.Measure();
measure.append(new music21.note.Note('G4'));
part.append(measure);

const score = new music21.stream.Score();
score.append(part);
```

### Time signature, key, clef
```javascript
s.timeSignature = new music21.meter.TimeSignature('6/8');
s.keySignature  = new music21.key.KeySignature(2);   // 2 sharps = D major
s.clef          = new music21.clef.TrebleClef();
```

### Rendering to the DOM
```javascript
s.appendNewDOM(document.getElementById('container'));  // create + append canvas/svg
s.replaceDOM(document.getElementById('container'));     // re-render in place
s.renderOptions.scaleFactor = { x: 0.8, y: 0.8 };
```

### Analysis
```javascript
const k = s.analyze('key');                 // Krumhansl key-finding
console.log(k.tonic.name, k.mode);          // e.g. "C" "major"
const amb = s.analyze('ambitus');           // pitch range (lowest→highest)
```

### MusicXML & Tiny Notation I/O
```javascript
// Tiny Notation: quick text → Stream
const tune = music21.tinyNotation.TinyNotation('4/4 c4 d e f g1');

// Parse MusicXML (async)
const sc = await music21.musicxml.xmlToScore(xmlString);
sc.appendNewDOM(document.body);
```

### Playback
```javascript
s.playStream();     // Web Audio / MIDI playback of the stream
s.stopStream();
```

## Capabilities Overview
- **Modeling**: notes, rests, chords, tuplets, ties, articulations, lyrics, multi-part scores.
- **Theory/analysis**: key detection, intervals, scales, roman numerals, chord identification, ambitus.
- **I/O**: MusicXML import/export, Tiny Notation, MIDI playback, ABC (partial).
- **Rendering**: VexFlow-backed staff notation with click handlers per note.

## How-To (worked recipes)

### How to color notes for analysis highlighting
Each note has a `.style.color`; set it, then re-render.
```javascript
const s = music21.tinyNotation.TinyNotation('4/4 c4 d e f');
s.notes.get(0).style.color = '#c0392b';   // highlight the tonic
s.notes.get(2).style.color = '#2980b9';
s.appendNewDOM(document.getElementById('container'));
```

### How to detect the key of a passage
```javascript
const s = music21.tinyNotation.TinyNotation('4/4 c4 d e f g a b c5');
const k = s.analyze('key');
console.log(`${k.tonic.name} ${k.mode} (correlation ${k.correlationCoefficient.toFixed(2)})`);
```

### How to make notes playable on click
```javascript
const s = music21.tinyNotation.TinyNotation('4/4 c4 e g c5');
s.renderOptions.events.click = (el /*, ev */) => el.playMIDI ? el.playMIDI() : el.playNote();
s.appendNewDOM(document.getElementById('container'));
```

### How to transpose a whole stream
```javascript
const s = music21.tinyNotation.TinyNotation('4/4 c4 d e f');
const up = s.transpose('M3');      // up a major third → E F# G# A
up.appendNewDOM(document.getElementById('container'));
```

## Do's and Don'ts

### ✅ Do
- Build music by appending elements to a Stream, then render the Stream — don't hand-place glyphs.
- Use `replaceDOM` to re-render after edits instead of appending duplicate canvases.
- Use scientific pitch names (`C#4`, `E-4`) and `quarterLength` for durations.
- Reach for Tiny Notation for quick test fixtures and generated fragments.
- Await the async `musicxml.xmlToScore` before rendering.

### ❌ Don't
- Don't expect full Python-music21 parity — the corpus, some analyzers, and exports are reduced in JS.
- Don't call `appendNewDOM` repeatedly on the same container (stacks canvases); use `replaceDOM`.
- Don't rely on it for publication engraving — it renders via VexFlow, not an engraving engine.
- Don't forget playback needs a user gesture to unlock Web Audio.
- Don't confuse `-` (flat) with `b` in pitch names — music21 uses `C-4` for C♭4.

## Styling, Theming & Customization
- **Per-element color**: `note.style.color` (any CSS color).
- **Scale**: `stream.renderOptions.scaleFactor = { x, y }`.
- **Layout**: `renderOptions.maxSystemWidth`, `staffLines`, `staffPadding`.
- **Fonts**: rendering uses VexFlow's music font; text uses the container's CSS font.
- **Events**: `renderOptions.events.click` / `resize` hooks for interactivity.

## Advanced Features
- **Roman numeral analysis** (`music21.roman.RomanNumeral('V7', 'C')`).
- **Scales & chords** generation (`music21.scale.MajorScale`, chord tables).
- **Interactive keyboards & metronome widgets** (`music21.keyboard`, `music21.tempo`).
- **MIDI in/out** via Web MIDI where supported.
- **Stream transformations**: `.flat`, `.getElementsByClass`, `.transpose`, `.augmentOrDiminish`.

## Common Pitfalls & Troubleshooting
- **Nothing renders** → container missing, or you appended to a hidden/zero-size element.
- **Duplicate scores** → repeated `appendNewDOM`; switch to `replaceDOM`.
- **No audio** → Web Audio locked; trigger `playStream` from a click.
- **MusicXML import gaps** → complex layout/notation may not round-trip fully.
- **Pitch spelling surprises** → `-` is flat; `C-` ≠ `B`. Enharmonics are preserved, not normalized.

## Framework Integration

### React wrapper
```jsx
import { useEffect, useRef } from 'react';
import * as music21 from 'music21j';

function Score({ tinyNotation }) {
  const hostRef = useRef(null);
  useEffect(() => {
    if (!hostRef.current) return;
    hostRef.current.innerHTML = '';                       // clear previous render
    const s = music21.tinyNotation.TinyNotation(tinyNotation);
    s.appendNewDOM(hostRef.current);
  }, [tinyNotation]);
  return <div ref={hostRef} />;
}
// <Score tinyNotation="4/4 c4 d e f g1" />
```

### How to identify a chord and its Roman numeral
```javascript
const c = new music21.chord.Chord(['G3', 'B3', 'D4', 'F4']);
console.log(c.commonName);            // "dominant seventh chord"
const rn = new music21.roman.RomanNumeral('V7', 'C');
console.log(rn.pitches.map(p => p.name)); // ['G','B','D','F']
```

## Integration Notes
- Pairs naturally with [musicxml](musicxml.md) as the interchange format and [vexflow](vexflow.md) as the renderer it wraps.
- For heavy analysis, generate/transform in browser music21j, export MusicXML, and hand off to [osmd](osmd.md) for richer display, or to Python music21 server-side.

## Best For / Avoid For
`music-theory`, `analysis`, `education`, `interactive-notation`, `algorithmic-composition`,
`browser-musicology` — choose music21j when reasoning about music matters as much as showing it.
Avoid for: publication engraving ([lilypond](lilypond.md)), tab + playback ([alphatab](alphatab.md)),
or minimal-footprint display of existing MusicXML ([osmd](osmd.md)).

## See Also
- [musicxml](musicxml.md) — primary I/O format
- [vexflow](vexflow.md) — the rendering engine music21j uses
- [osmd](osmd.md) — richer MusicXML display
- [abcjs](abcjs.md) — lighter text-notation alternative
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
