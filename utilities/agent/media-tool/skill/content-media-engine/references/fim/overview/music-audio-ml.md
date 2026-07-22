# Music Notation + Audio + ML

This category covers three related families of browser-and-toolchain solutions: music-notation formats and renderers that turn structured score data into engraved sheet music, audio frameworks that synthesize and schedule sound, and a machine-learning library for creative coding. The shared consumer pattern is that an LLM emits a structured artifact — notation text/XML/JSON, rendering-API code, or an audio graph — which a downstream engine renders into a visual score, an audible performance, or an interactive canvas.

## Solutions

### Music Notation — Formats

#### MusicXML
The industry-standard, W3C-standardized XML interchange format for sheet music, supported by 250+ apps (Finale, Sibelius, MuseScore). The LLM emits a `<score-partwise>` document; a renderer such as OSMD or a toolkit like music21 consumes it to produce engraved output. Pick it as the safe interoperability default whenever a score must move between tools. [Detail](music-audio-ml/musicxml.md)

#### MEI (Music Encoding Initiative)
An XML format that encodes notation plus rich scholarly metadata (variants, editorial marks, sources) for academic and critical-edition work. The LLM emits an `<mei>` document rendered chiefly by Verovio (typically to SVG). Choose it over MusicXML when editorial apparatus and metadata matter more than broad software support. [Detail](music-audio-ml/mei.md)

#### MNX (Music Notation eXtensible)
The W3C's next-generation, JSON-based successor to MusicXML, emphasizing web-native encoding and extensibility. The LLM emits an MNX JSON `score` structure that a consuming app parses and hands to a renderer. Reach for it to future-proof a project, but note it is still a draft with limited implementation today. [Detail](music-audio-ml/mnx.md)

#### SMuFL (Standard Music Font Layout)
An open standard mapping 2400+ musical symbols to Unicode PUA codepoints and font glyphs — the glyph foundation that renderers rely on, not a renderer itself. The LLM emits text using SMuFL codepoints plus a compliant font (e.g. Bravura); a layout engine is still required to place glyphs into real notation. Use it when building a rendering system that needs consistent, font-independent glyphs. [Detail](music-audio-ml/smufl.md)

### Music Notation — Renderers & Toolkits

#### VexFlow
A pure-JavaScript, low-level API for rendering standard notation and guitar tablature to SVG/Canvas; it also powers OSMD and music21j. The LLM emits VexFlow JS that builds staves, notes, and voices (or terse EasyScore strings), drawn client-side with no audio. Pick it when generating notation programmatically and you want fine control. [Detail](music-audio-ml/vexflow.md)

#### OSMD (OpenSheetMusicDisplay)
A high-level TypeScript/JS library that renders MusicXML files in the browser using VexFlow underneath, with automatic layout. The LLM supplies a MusicXML document; `osmd.load()` + `osmd.render()` produce an engraved SVG score. Choose it over VexFlow when your input is a complete MusicXML score and you want layout handled for you. [Detail](music-audio-ml/osmd.md)

#### abcjs
A lightweight JS library that parses, renders, and plays ABC notation, turning human-readable ABC text into SVG plus built-in MIDI playback. The LLM emits an ABC tune string rendered via `abcjs.renderAbc(...)`. Best for simple folk/educational tunes where concise text and integrated audio beat expressive range. [Detail](music-audio-ml/abcjs.md)

#### AlphaTab
A cross-platform notation/tablature engine with built-in audio synthesis, specialized in Guitar Pro formats (GP3–GP7). The LLM supplies a loader config plus score data (GP binary or MusicXML); `AlphaTabApi` renders tab/notation and plays it with a soundfont. Reach for it specifically for guitar/bass apps needing Guitar Pro support and playback. [Detail](music-audio-ml/alphatab.md)

#### Music21j
The JavaScript port of MIT's music21 musicology toolkit, adding theory/analysis (key detection, intervals) on top of notation rendered through bundled VexFlow, with MIDI playback. The LLM emits Music21j JS building streams of notes, displayed and analyzed in-browser. Choose it when the task is understanding music, not just displaying it. [Detail](music-audio-ml/music21j.md)

### Music Notation — Cloud SaaS

#### Flat API
A cloud REST service for programmatic score creation/editing with real-time collaboration, revision history, and multi-format export (PDF, MIDI, MP3, MusicXML, PNG). The LLM emits REST/JSON requests and MusicXML bodies against OAuth2-authenticated endpoints; rendering and export happen server-side. Pick it for managed collaboration and server-side export without building a pipeline. [Detail](music-audio-ml/flat-api.md)

#### Noteflight API
A commercial SaaS for embedding a full interactive notation editor with cloud storage, collaboration, and export. The LLM emits client-API JS plus MusicXML to initialize a hosted editor widget with playback. Its sibling to Flat, but emphasizing a drop-in full editor and education tooling over a REST/webhook surface. [Detail](music-audio-ml/noteflight-api.md)

### Audio

#### Tone.js
A high-level Web Audio framework for interactive music — synths, samplers, effects, and precise transport scheduling. The LLM emits Tone.js JS building an instrument/effects graph and scheduled events; `Tone.start()` + `Transport.start()` play it. The artifact is sound, not an image — the natural playback partner for the visual-only notation renderers here. [Detail](music-audio-ml/tone_js.md)

#### Web Audio API
The native browser API for audio synthesis via a modular graph of connectable nodes, offering low-level, sample-accurate control with no dependencies. The LLM emits JS creating an `AudioContext` and wiring oscillator/gain nodes to the destination. It is the foundation Tone.js builds on — reach for it directly when you need fine node control or a minimal footprint. [Detail](music-audio-ml/web-audio-api.md)

### ML for Creative Coding

#### ml5.js
A friendly ML library wrapping pre-trained models (image classification, pose/hand/face detection, style transfer, sound classification) behind a simple API, designed to work with p5.js. The LLM emits ml5 JS that loads a model and draws its inference results to a canvas. The category outlier — a bridge from pre-trained models into interactive p5.js visuals rather than notation or audio synthesis. [Detail](music-audio-ml/ml5_js.md)

## Source
- Per-solution detail files: `fim/overview/music-audio-ml/{solution}.md`
