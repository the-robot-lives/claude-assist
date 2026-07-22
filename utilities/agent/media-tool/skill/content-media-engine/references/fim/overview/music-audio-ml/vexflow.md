# VexFlow

## What
VexFlow is a pure-JavaScript library for rendering standard music notation and guitar tablature to SVG or Canvas. It is a low-level, programmatic notation-rendering API; its primary consumer is browser JavaScript. It powers higher-level tools (OSMD, music21j) as their underlying renderer.

## How
- **LLM emits:** VexFlow JavaScript that constructs notation objects — a `Renderer`, a `Stave` (with clef/time signature), `StaveNote`s (`{ keys: ['c/4'], duration: 'q' }`), and a `Voice` formatted via `Formatter`. A higher-level `EasyScore`/`Factory` API accepts terse note strings like `'C4/q, D4, E4, F4'`.
- **Render step:** `import { Renderer, Stave, StaveNote, Voice, Formatter } from 'vexflow'`, create `new Renderer(div, Renderer.Backends.SVG)`, resize, draw the stave, then `new Formatter().joinVoices([voice]).format([voice], width)` and `voice.draw(context, stave)`. Install via `npm install vexflow` or CDN. Client-side only; no server required.
- **Final artifact:** music notation drawn as SVG (or Canvas) in the browser — a scalable, crisp static score. There is no built-in audio (playback needs a separate library such as Tone.js).

## Why
- **Reach for it when:** you are generating notation dynamically or need fine control — interactive music-education apps, dynamic score generation, real-time notation editors, and guitar-tablature applications. Pure JS with no external dependencies, SVG output, and comprehensive coverage (tabs, percussion, articulations).
- **Limitations:** manual positioning for complex layouts; no built-in playback; learning curve for complex scores; memory/mobile performance concerns on large scores; limited screen-reader accessibility.
- **Relative to siblings:** VexFlow is the programmatic notation API; OSMD is the higher-level MusicXML-file renderer built on top of it. Use VexFlow when you construct notation in code and want control; use OSMD when you have a MusicXML file and want automatic layout. Pair with Tone.js/Web Audio API when playback is needed.

## Source
- Solution reference: `fim/solution/vexflow.md`
- Nested use-case detail: `fim/solution/vexflow/use-case/music-notation.md`
