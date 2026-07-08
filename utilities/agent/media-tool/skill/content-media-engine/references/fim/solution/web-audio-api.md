# Web Audio API — Native Browser Audio Graph

The Web Audio API is the browser's built-in system for synthesizing, processing, and
analyzing audio through a **node graph**: sources (oscillators, buffers, media) connect
through processing nodes (gain, filter, delay, panner) to an `AudioContext.destination`
(the speakers). It offers sample-accurate scheduling and low-level control with zero
dependencies — at the cost of writing the musical structure yourself. Frameworks like
Tone.js are built on top of it.

**Standard**: W3C Web Audio API (Recommendation)  **License**: Native platform API (no bundle)
**Runtime**: All modern browsers (`AudioContext`; older Safari `webkitAudioContext`)  **Constraint**: needs a user gesture to start

## Official Resources & Documentation
- MDN guide: https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
- Spec: https://www.w3.org/TR/webaudio/
- MDN: Best practices — https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API/Best_practices
- AudioWorklet: https://developer.mozilla.org/en-US/docs/Web/API/AudioWorklet

## Setup & Context Lifecycle

### Create and unlock the AudioContext
An `AudioContext` starts **suspended** under autoplay policy; resume it from a user gesture.
```javascript
const ctx = new (window.AudioContext || window.webkitAudioContext)();

document.querySelector('#start').addEventListener('click', async () => {
  if (ctx.state === 'suspended') await ctx.resume();
});
```
`ctx.currentTime` is the master clock (seconds, monotonic) you schedule against.
`ctx.sampleRate` is typically 44100 or 48000.

## Core Node Reference

The pattern is always **create node → configure → `connect()` → start/schedule**. Audio
flows left-to-right until it reaches `ctx.destination`.

### OscillatorNode (tone generator)
```javascript
const osc = ctx.createOscillator();
osc.type = 'sine';                       // 'sine'|'square'|'sawtooth'|'triangle'|'custom'
osc.frequency.setValueAtTime(440, ctx.currentTime);  // A4
osc.connect(ctx.destination);
osc.start();
osc.stop(ctx.currentTime + 1);           // oscillators are one-shot; create a new one to replay
```

### GainNode (volume / envelopes)
```javascript
const gain = ctx.createGain();
gain.gain.setValueAtTime(0, ctx.currentTime);
gain.gain.linearRampToValueAtTime(0.3, ctx.currentTime + 0.02);  // attack
gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 1); // decay/release
osc.connect(gain).connect(ctx.destination);
```

### AudioParam scheduling methods
```javascript
param.setValueAtTime(v, t);
param.linearRampToValueAtTime(v, t);
param.exponentialRampToValueAtTime(v, t);   // v must be > 0
param.setTargetAtTime(v, t, timeConstant);  // exponential approach
param.setValueCurveAtTime(float32Array, t, duration);
param.cancelScheduledValues(t);
```

### BiquadFilterNode
```javascript
const filter = ctx.createBiquadFilter();
filter.type = 'lowpass';                 // lowpass|highpass|bandpass|notch|peaking|lowshelf|highshelf
filter.frequency.value = 1000;
filter.Q.value = 8;
osc.connect(filter).connect(ctx.destination);
```

### AudioBufferSourceNode (sample playback)
```javascript
const buf = await fetch('kick.wav').then(r => r.arrayBuffer()).then(b => ctx.decodeAudioData(b));
const src = ctx.createBufferSource();
src.buffer = buf;
src.playbackRate.value = 1.0;            // pitch/speed
src.connect(ctx.destination);
src.start();                             // one-shot; recreate to replay
```

### Other useful nodes
```javascript
const pan   = ctx.createStereoPanner(); pan.pan.value = -0.5;      // left
const delay = ctx.createDelay(1.0);     delay.delayTime.value = 0.25;
const conv  = ctx.createConvolver();    // reverb (needs an impulse-response buffer)
const comp  = ctx.createDynamicsCompressor();
const merger = ctx.createChannelMerger(2);
const splitter = ctx.createChannelSplitter(2);
```

### AnalyserNode (visualization)
```javascript
const analyser = ctx.createAnalyser();
analyser.fftSize = 2048;
osc.connect(analyser);
const data = new Uint8Array(analyser.frequencyBinCount);
function frame() {
  analyser.getByteFrequencyData(data);   // or getByteTimeDomainData for waveform
  // draw `data` to a canvas here
  requestAnimationFrame(frame);
}
frame();
```

## How-To (worked recipes)

### How to play a pitched note with an ADSR envelope
```javascript
function playNote(freq, when = ctx.currentTime, dur = 0.5) {
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.frequency.value = freq;
  g.gain.setValueAtTime(0, when);
  g.gain.linearRampToValueAtTime(0.4, when + 0.02);          // attack
  g.gain.linearRampToValueAtTime(0.25, when + 0.1);          // decay→sustain
  g.gain.exponentialRampToValueAtTime(0.0001, when + dur);   // release
  osc.connect(g).connect(ctx.destination);
  osc.start(when); osc.stop(when + dur);
}
playNote(440);
```

### How to schedule a melody without timer drift
Schedule ahead against `ctx.currentTime`; never `setTimeout` per note.
```javascript
const freqs = [261.63, 293.66, 329.63, 349.23, 392.00]; // C D E F G
let t = ctx.currentTime + 0.1;
for (const f of freqs) { playNote(f, t, 0.4); t += 0.5; }
```

### How to build a lowpass "wah" sweep
```javascript
const osc = ctx.createOscillator(); osc.type = 'sawtooth'; osc.frequency.value = 110;
const filter = ctx.createBiquadFilter(); filter.type = 'lowpass'; filter.Q.value = 12;
filter.frequency.setValueAtTime(200, ctx.currentTime);
filter.frequency.linearRampToValueAtTime(4000, ctx.currentTime + 1);
filter.frequency.linearRampToValueAtTime(200, ctx.currentTime + 2);
osc.connect(filter).connect(ctx.destination);
osc.start(); osc.stop(ctx.currentTime + 2);
```

### How to visualize audio on a canvas
```javascript
const analyser = ctx.createAnalyser(); analyser.fftSize = 1024;
source.connect(analyser);
const buf = new Uint8Array(analyser.frequencyBinCount);
const cv = canvas.getContext('2d');
(function draw() {
  analyser.getByteFrequencyData(buf);
  cv.clearRect(0, 0, canvas.width, canvas.height);
  buf.forEach((v, i) => cv.fillRect(i * 3, canvas.height - v, 2, v));
  requestAnimationFrame(draw);
})();
```

## Do's and Don'ts

### ✅ Do
- Resume the `AudioContext` from a user gesture before producing sound.
- Schedule everything against `ctx.currentTime` with AudioParam methods for sample accuracy.
- Ramp gains (attack/release) to avoid clicks — never jump a gain instantly under a live signal.
- Reuse one `AudioContext` for the whole app; contexts are heavyweight and limited in number.
- Use `exponentialRampToValueAtTime` for perceptually natural volume/pitch changes (target must be > 0).

### ❌ Don't
- Don't `new AudioContext()` per sound — you'll hit the browser's context limit.
- Don't reuse an `OscillatorNode`/`BufferSourceNode` after `stop()` — they're single-use; create fresh ones.
- Don't drive rhythm with `setTimeout`/`setInterval` — timer jitter ruins timing; schedule ahead.
- Don't `exponentialRampToValueAtTime(0, …)` — zero is illegal for exponential ramps; use a tiny value like `0.0001`.
- Don't forget to connect to `ctx.destination` (directly or through the chain) or there's silence.

## Styling, Theming & Customization
"Styling" = sound design and the visual side you render from analysis:
- **Timbre**: oscillator `type`, `PeriodicWave` (custom harmonics via `createPeriodicWave`).
- **Envelopes/filters**: shape ADSR and filter sweeps for character.
- **Spatialization**: `StereoPannerNode`, `PannerNode` (3D/HRTF) for placement.
- **Visualization**: feed an `AnalyserNode` into canvas/WebGL to draw spectra/waveforms.

## Advanced Features
- **AudioWorklet**: run custom DSP in a dedicated audio thread (`AudioWorkletProcessor`) for
  synths/effects impossible with built-in nodes.
- **OfflineAudioContext**: render/bounce audio faster-than-realtime to an `AudioBuffer` for export.
- **ConvolverNode**: real impulse-response reverb.
- **MediaStream/MediaElement sources**: process microphone or `<audio>`/`<video>` audio.
- **Channel splitting/merging** for multi-channel routing.

## Common Pitfalls & Troubleshooting
- **Silence** → context suspended (no gesture), or missing `connect(ctx.destination)`.
- **"cannot call start more than once"** → oscillators/buffer sources are one-shot; make new ones.
- **Clicks/pops** → instantaneous gain changes; ramp them.
- **Timing drift** → scheduling with JS timers instead of `currentTime`.
- **Exponential ramp error** → target value 0; use a small positive epsilon.
- **Safari quirks** → use `webkitAudioContext` fallback; some methods differ.

### How to bounce audio to a WAV offline
`OfflineAudioContext` renders faster than realtime into a buffer you can encode.
```javascript
const offline = new OfflineAudioContext(2, 44100 * 2, 44100); // 2ch, 2s
const osc = offline.createOscillator();
osc.frequency.value = 440;
osc.connect(offline.destination);
osc.start(); osc.stop(2);
const rendered = await offline.startRendering();   // AudioBuffer → encode to WAV/PCM
```

### How to run custom DSP with an AudioWorklet
```javascript
// worklet-processor.js
class GainProcessor extends AudioWorkletProcessor {
  process(inputs, outputs) {
    const input = inputs[0], output = outputs[0];
    for (let ch = 0; ch < output.length; ch++)
      for (let i = 0; i < output[ch].length; i++)
        output[ch][i] = (input[ch]?.[i] ?? 0) * 0.5;
    return true;
  }
}
registerProcessor('gain-processor', GainProcessor);

// main thread
await ctx.audioWorklet.addModule('worklet-processor.js');
const node = new AudioWorkletNode(ctx, 'gain-processor');
source.connect(node).connect(ctx.destination);
```

## Integration Notes
- Prefer **[tone_js](tone_js.md)** for musical structure (Transport, synths, sequencing) and drop to raw Web Audio only for custom DSP/`AudioWorklet`.
- Powers playback in [abcjs](abcjs.md), [alphatab](alphatab.md), and OSMD-based practice apps under the hood.
- Combine with canvas/WebGL for audio-reactive visuals.

## Best For / Avoid For
`custom-dsp`, `low-level-audio`, `audio-visualization`, `game-sound`, `synths`,
`no-dependencies` — choose raw Web Audio when you need full control or minimal footprint.
Avoid for: musical timing/sequencing convenience (use [tone_js](tone_js.md)), notation
(use [vexflow](vexflow.md)/[osmd](osmd.md)), or non-browser environments.

## See Also
- [tone_js](tone_js.md) — the high-level framework built on this API
- [alphatab](alphatab.md) — uses Web Audio for SoundFont playback
- [osmd](osmd.md) / [music21j](music21j.md) — notation to sonify through these nodes
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
