# abcjs

## What
abcjs is a JavaScript library that parses, renders, and plays ABC music notation, turning simple text-based ABC into SVG musical scores with built-in MIDI playback. Its primary consumer is browser JavaScript — it is widely used for educational apps, folk-music collections, and interactive notation platforms. MIT-licensed, ~400KB minified (~120KB gzipped), supported across all modern browsers.

## How
- **LLM emits:** ABC notation text (the human-readable ABC tune format) plus a target element id.
- **Render step:** Call `abcjs.renderAbc(elementId, abcString, options)` to render the ABC string into SVG in the target DOM element. Install via `npm install abcjs` or a CDN script (`abcjs-basic-min.js`); add `abcjs-audio-min.js` for advanced playback. ES module and CommonJS imports are both supported (`import abcjs from 'abcjs'`).
- **Final artifact:** SVG musical score in the browser; optionally an interactive player with integrated MIDI audio (so the artifact can be both a visual score and audible playback).

## Why
- **Reach for it when:** you want lightweight, fast, text-driven notation with built-in MIDI and no external audio dependency — folk/traditional music, education/theory tools, real-time notation editors, large collections of simple tunes, and musical examples in docs. ABC text is version-control friendly and screen-reader-compatible (SVG output).
- **Limitations:** scope is bounded by what ABC notation can express; less suitable for complex classical arrangements, offers limited fine-grained layout control, print quality trails dedicated engraving software, some modern-notation elements are unsupported, and performance degrades on very long compositions.
- **Relative to siblings:** abcjs is the "simple syntax, lightweight, batteries-included audio" option. Where VexFlow gives a low-level programmatic notation API and OSMD renders full MusicXML files, abcjs trades expressive range for a concise text format and integrated playback — best when the input is a short human-authored tune rather than a rich score.

## Source
- Solution reference: `fim/solution/abcjs.md`
