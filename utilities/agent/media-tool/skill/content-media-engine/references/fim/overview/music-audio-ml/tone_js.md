# Tone.js

## What
Tone.js is a Web Audio framework for creating interactive music in the browser, providing synthesis, sampling, effects, and precise scheduling. It produces audio (not notation) and its primary consumer is browser JavaScript running on the Web Audio API.

## How
- **LLM emits:** Tone.js JavaScript — instrument/effect graphs and scheduled events, e.g. `new Tone.Synth().toDestination()`, `synth.triggerAttackRelease('C4', '8n')`, a `Tone.Sequence(...)`, or a `Tone.Sampler({ urls, baseUrl })`.
- **Execute step:** `import * as Tone from 'tone'` (or CDN `Tone.min.js`), build the synth/effects chain (`synth.connect(new Tone.Reverb(2).toDestination())`), then `await Tone.start()` and `Tone.Transport.start()` to begin scheduled playback. Install via `npm install tone`.
- **Final artifact:** rendered/played audio in the browser — the artifact is sound, not an image. No visual notation is produced.

## Why
- **Reach for it when:** you need musical audio playback and sequencing — playback for notation libraries, interactive music apps, generative music systems, audio effects/processing, and MIDI-like sequencing in the browser. Comprehensive synthesis, precise timing/scheduling, and rich effects; pairs with any notation library for sound.
- **Limitations:** no notation rendering (audio only); requires Web Audio API support; a learning curve for synthesis concepts.
- **Relative to siblings:** Tone.js is the high-level audio engine layered on top of the raw Web Audio API — it trades the low-level node control of Web Audio for musical abstractions (synths, transport, sequences, effects). It is the natural playback partner for the visual-only renderers in this category (VexFlow, OSMD), which produce scores but no sound.

## Source
- Solution reference: `fim/solution/tone_js.md`
