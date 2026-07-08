# Tone.js — Web Audio Framework for Interactive Music

Tone.js is a high-level framework built on top of the Web Audio API for making interactive
music in the browser. It adds a musical **Transport** (a synchronized timeline with tempo,
bars/beats, loops), a family of **synths** and **samplers**, an **effects** chain, and
precise **event scheduling** — the things raw Web Audio makes you build by hand. It renders
no notation; it is the *sound* half of a notation-plus-playback stack.

**Current Version**: 15.x (`tone`)  **License**: MIT
**Bundle**: ~200KB min+gzip  **Runtime**: Browser (Web Audio); requires a user gesture to start audio

## Official Resources & Documentation
- Site & interactive docs: https://tonejs.github.io/
- API reference: https://tonejs.github.io/docs/
- GitHub: https://github.com/Tonejs/Tone.js
- Examples: https://tonejs.github.io/examples/
- npm: https://www.npmjs.com/package/tone

## Installation & Setup

### Package manager
```bash
npm install tone
```
```javascript
import * as Tone from 'tone';
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/tone@15/build/Tone.js"></script>
```

### Starting audio (required)
Browsers block audio until a user gesture. Call `Tone.start()` inside a click/tap handler.
```javascript
document.querySelector('#play').addEventListener('click', async () => {
  await Tone.start();          // resumes the AudioContext
  // now safe to trigger sound
});
```

## Core API Reference

The mental model: **sources** (synths/players) → **effects** → **destination** (speakers),
all scheduled against the **Transport** clock. Times use seconds, notation (`'4n'`, `'8n'`,
`'2t'`), or bars:beats:sixteenths (`'1:2:0'`).

### Synths
```javascript
const synth = new Tone.Synth().toDestination();               // monophonic
synth.triggerAttackRelease('C4', '8n');                       // note, duration

const poly = new Tone.PolySynth(Tone.Synth).toDestination();  // chords
poly.triggerAttackRelease(['C4', 'E4', 'G4'], '2n');

const fm  = new Tone.FMSynth().toDestination();
const am  = new Tone.AMSynth().toDestination();
const duo = new Tone.DuoSynth().toDestination();
const membrane = new Tone.MembraneSynth().toDestination();    // kick/drum
const noise    = new Tone.NoiseSynth().toDestination();       // snare/hat
```

### `triggerAttack` / `triggerRelease` / `triggerAttackRelease`
```javascript
synth.triggerAttack('A4');                     // start (hold)
synth.triggerRelease();                        // stop
synth.triggerAttackRelease('A4', '4n', '+0.5');// note, dur, at (0.5s from now)
```

### Sampler (pitched playback of audio files)
```javascript
const sampler = new Tone.Sampler({
  urls: { 'C4': 'C4.mp3', 'D#4': 'Ds4.mp3', 'F#4': 'Fs4.mp3', 'A4': 'A4.mp3' },
  baseUrl: 'https://tonejs.github.io/audio/salamander/',
  release: 1,
  onload: () => console.log('samples ready')
}).toDestination();
sampler.triggerAttackRelease(['C4', 'E4'], 2);  // interpolates missing pitches
```

### Transport — the musical clock
```javascript
Tone.Transport.bpm.value = 120;
Tone.Transport.timeSignature = [4, 4];
Tone.Transport.start();                         // begin the timeline
Tone.Transport.stop();
Tone.Transport.bpm.rampTo(140, 5);              // accelerando over 5s
```

### Scheduling: Sequence / Loop / Part / schedule
```javascript
// Sequence: cycle values at a subdivision
const seq = new Tone.Sequence((time, note) => {
  synth.triggerAttackRelease(note, '8n', time);
}, ['C4', 'E4', 'G4', 'B4'], '4n');
seq.start(0);

// Loop: repeat a callback
new Tone.Loop((time) => synth.triggerAttackRelease('C2', '8n', time), '4n').start(0);

// Part: fixed events with explicit times
new Tone.Part((time, ev) => synth.triggerAttackRelease(ev.note, ev.dur, time), [
  { time: '0:0', note: 'C4', dur: '4n' },
  { time: '0:2', note: 'G4', dur: '4n' },
]).start(0);

Tone.Transport.start();
```

### Effects chain
```javascript
const reverb  = new Tone.Reverb({ decay: 3, wet: 0.4 });
const delay   = new Tone.FeedbackDelay('8n', 0.4);
const chorus  = new Tone.Chorus(4, 2.5, 0.5).start();
const dist    = new Tone.Distortion(0.4);
synth.chain(dist, chorus, delay, reverb, Tone.Destination); // source → …fx… → out
```

### Signals & envelopes
```javascript
const env = new Tone.AmplitudeEnvelope({ attack: 0.1, decay: 0.2, sustain: 0.5, release: 1 });
const osc = new Tone.Oscillator('C4', 'sine').connect(env);
env.toDestination(); osc.start();
env.triggerAttackRelease('2n');
```

## Building Blocks Overview
- **Sources**: `Synth`, `PolySynth`, `FMSynth`, `AMSynth`, `MonoSynth`, `MembraneSynth`,
  `MetalSynth`, `NoiseSynth`, `Sampler`, `Player`, `Oscillator`, `GrainPlayer`.
- **Effects**: `Reverb`, `FeedbackDelay`, `PingPongDelay`, `Chorus`, `Distortion`,
  `Phaser`, `Tremolo`, `AutoFilter`, `BitCrusher`, `Freeverb`, `Compressor`, `EQ3`.
- **Timing**: `Transport`, `Sequence`, `Loop`, `Part`, `Pattern`, `Time`, `Frequency`.
- **Components**: `Envelope`, `LFO`, `Gain`, `Panner`, `Channel`, `Meter`, `FFT`, `Waveform`.

## How-To (worked recipes)

### How to play a melody in time
```javascript
await Tone.start();
const synth = new Tone.Synth().toDestination();
const notes = ['C4','D4','E4','F4','G4','A4','B4','C5'];
const seq = new Tone.Sequence((time, n) => synth.triggerAttackRelease(n, '8n', time), notes, '8n');
Tone.Transport.bpm.value = 100;
seq.start(0);
Tone.Transport.start();
```

### How to build a drum pattern
```javascript
const kick  = new Tone.MembraneSynth().toDestination();
const snare = new Tone.NoiseSynth({ envelope: { attack: 0.001, decay: 0.2 } }).toDestination();
new Tone.Loop(t => kick.triggerAttackRelease('C1', '8n', t), '4n').start(0);
new Tone.Loop(t => snare.triggerAttackRelease('8n', t), '2n').start('4n'); // backbeat
Tone.Transport.start();
```

### How to add reverb + delay to a synth
```javascript
const synth = new Tone.PolySynth().toDestination();
const fx = new Tone.Reverb(2.5);
const echo = new Tone.FeedbackDelay('8n', 0.35);
synth.disconnect();
synth.chain(echo, fx, Tone.Destination);
synth.triggerAttackRelease(['C4','E4','G4'], '2n');
```

### How to drive playback from a notation library's cursor
```javascript
const synth = new Tone.PolySynth().toDestination();
function onCursorStep(pitchNames /* e.g. ['C4','E4'] */, durSeconds) {
  synth.triggerAttackRelease(pitchNames, durSeconds);
}
// Call onCursorStep from OSMD/music21j as the cursor advances.
```

## Do's and Don'ts

### ✅ Do
- Call `await Tone.start()` inside a user gesture before any sound.
- Schedule events with the `time` argument from callbacks (`triggerAttackRelease(note, dur, time)`) for sample-accurate timing — never rely on `setTimeout`.
- Reuse a few synths/effects; connect once and re-trigger.
- Use `PolySynth` for chords; a plain `Synth` is monophonic and cuts off overlaps.
- Dispose unused nodes (`node.dispose()`) in SPAs to free audio resources.

### ❌ Don't
- Don't create a new synth per note — you'll leak nodes and glitch. Trigger an existing one.
- Don't schedule with JS timers; use the Transport / event classes for musical timing.
- Don't forget effects need `.toDestination()` (or a chain to it) or they're silent.
- Don't start `Tone.Transport` and expect one-shot sounds to play — one-shots use `triggerAttackRelease` directly; the Transport drives *scheduled* events.
- Don't ignore the autoplay policy — audio started outside a gesture stays suspended.

## Styling, Theming & Customization
This is audio, not visuals — "styling" means **sound design**:
- **Oscillator type**: `synth.oscillator.type = 'sawtooth' | 'square' | 'triangle' | 'sine'`.
- **Envelope (ADSR)**: shape attack/decay/sustain/release for pluck vs pad.
- **Effects wet/dry**: `fx.wet.value = 0.3` blends processed vs dry signal.
- **Filters/EQ**: `Tone.Filter`, `EQ3` shape timbre.
- Pair with a visualizer (`Tone.Analyser`/`Waveform`/`FFT`) to render sound to canvas.

## Advanced Features
- **Offline rendering**: `Tone.Offline(cb, duration)` bounces audio to a buffer (export to WAV).
- **Buses & sidechaining** via `Tone.Channel`, `Tone.Gain`, and signal connections.
- **LFO modulation** of any AudioParam (`lfo.connect(filter.frequency)`).
- **Analysers** (`Tone.Analyser`, `Meter`, `FFT`, `Waveform`) for visualization.
- **MIDI** via the Web MIDI API + Tone scheduling for controllers.

## Common Pitfalls & Troubleshooting
- **No sound at all** → `Tone.start()` not called from a gesture; AudioContext suspended.
- **Timing jitter** → used `setTimeout` instead of the scheduled `time` argument.
- **Clicks/pops** → envelopes too abrupt; add small attack/release.
- **Only one note plays** → monophonic `Synth`; switch to `PolySynth`.
- **Sampler silent** → files 404 / still loading; wait for `onload`.
- **CPU spikes** → too many live nodes/reverbs; reuse and `dispose()`.

## Integration Notes
- **Notation playback**: drive Tone from [osmd](osmd.md)'s cursor or [music21j](music21j.md) streams for practice apps.
- **Under the hood** it's the [web-audio-api](web-audio-api.md); drop to raw nodes for custom DSP, use Tone for musical structure.
- **React/Vue**: create audio graph after a gesture; `dispose()` on unmount.

## Best For / Avoid For
`interactive-music`, `generative-audio`, `playback`, `sequencing`, `sound-design`,
`browser-instruments` — choose Tone.js when you need musical timing and synthesis without
hand-rolling Web Audio.
Avoid for: notation rendering (use [vexflow](vexflow.md)/[osmd](osmd.md)), ultra-low-level DSP
where you want raw nodes ([web-audio-api](web-audio-api.md)), or non-browser audio.

## See Also
- [web-audio-api](web-audio-api.md) — the native layer Tone.js is built on
- [osmd](osmd.md) / [music21j](music21j.md) — notation whose playback Tone can drive
- [alphatab](alphatab.md) — bundles its own synthesis (SoundFont) for tab
- [abcjs](abcjs.md) — has built-in MIDI playback as a simpler alternative
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
