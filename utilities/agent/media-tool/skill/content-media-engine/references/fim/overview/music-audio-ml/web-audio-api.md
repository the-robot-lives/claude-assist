# Web Audio API

## What
The Web Audio API is the native browser API for audio processing and synthesis via a modular routing system of connectable audio nodes. It produces audio (not notation) with low-level, sample-accurate control. Its consumer is browser JavaScript; it is a native API with no external dependencies.

## How
- **LLM emits:** Web Audio JavaScript — an `AudioContext` plus a node graph, e.g. `audioContext.createOscillator()` and `createGain()`, configured (`oscillator.type`, `frequency.setValueAtTime(440, ...)`, `gain.setValueAtTime(0.3, ...)`) and wired `oscillator -> gain -> audioContext.destination`.
- **Execute step:** create `new (window.AudioContext || window.webkitAudioContext)()`, build and connect nodes, then `oscillator.start()` / `stop(...)`. Because browsers require a user gesture, resume a suspended context on user interaction (`if (audioContext.state === 'suspended') audioContext.resume()`). No install — it is a native browser API (see MDN).
- **Final artifact:** rendered/played audio through the speakers — the artifact is sound, not an image.

## Why
- **Reach for it when:** you need direct, real-time control of audio — interactive audio apps, synthesizers/sequencers, real-time effects processing, game sound engines, and audio visualization. Strengths are low-level node/parameter control, sub-millisecond timing, a modular audio-graph architecture, and zero dependencies.
- **Limitations:** browser only (not available in Node.js or other runtimes); audio context must be resumed after a user gesture; some feature variance across browsers; complex graphs can impact CPU.
- **Relative to siblings:** Web Audio API is the low-level foundation; Tone.js is the higher-level musical framework built on top of it. Reach directly for Web Audio when you need fine-grained node control or minimal footprint; reach for Tone.js when you want musical abstractions (transport, sequences, synths, effects) without wiring nodes by hand.

## Source
- Solution reference: `fim/solution/web-audio-api.md`
