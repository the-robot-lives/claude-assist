# Music21j

## What
Music21j is the JavaScript port of MIT's music21 Python toolkit for computer-aided musicology, enabling music analysis and visualization in the browser. It produces notation (rendered via its bundled VexFlow) plus theory/analysis results and MIDI playback. Primary consumer is browser JavaScript.

## How
- **LLM emits:** Music21j JavaScript that builds musical objects — `new music21.note.Note('C4')`, a `music21.stream.Stream()` container to which notes are appended, or a parsed MusicXML string via `music21.musicxml.parse(...)`.
- **Render step:** display a stream into the DOM with `s.appendNewDOM(document.getElementById('music-container'))` (notation rendered through built-in VexFlow); analyze with `s.analyze('key')`; play with `s.playStream()` (MIDI). Install via CDN (`music21.min.js`) or `npm install music21j`.
- **Final artifact:** interactive in-browser notation with analysis annotations, plus MIDI playback (so the output spans visual notation, computed analysis, and audio).

## Why
- **Reach for it when:** you want music theory/analysis capability in the browser — music education and theory apps, basic in-browser analysis, interactive notation tied to analysis, academic musicology tools, and simple notation editing. Backed by MIT's established music21 research toolkit with MusicXML import/export.
- **Limitations:** smaller feature set than the Python version; thinner documentation than the parent library; performance constraints in the browser; fewer corpus/analysis tools.
- **Relative to siblings:** Music21j is the analysis-first option — it renders notation through VexFlow and plays via Web Audio, but its differentiator is theory/analysis (key detection, intervals, scales) rather than pure engraving. Choose it when the task is understanding music, not just displaying it.

## Source
- Solution reference: `fim/solution/music21j.md`
