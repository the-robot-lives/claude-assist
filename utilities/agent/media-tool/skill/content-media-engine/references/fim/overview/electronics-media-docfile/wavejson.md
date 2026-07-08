# WaveJSON

## What
WaveJSON is the JSON format specification for waveform descriptions — the interchange standard underlying digital timing diagrams (it is the format WaveDrom consumes). It is a tool-agnostic data format, not a renderer; its consumers are any parser/renderer that speaks WaveJSON, across platforms.

## How
- **LLM emits:** a WaveJSON document — a `signal` array of `{name, wave, data}` objects (with `|` for gaps and `{}` for spacers) and an optional `config` block (e.g. `{"hscale": 2}`).
- **Render path:** WaveJSON has no native rendering; pass it to a renderer (WaveDrom) or a converter such as `wavejson2svg`. VCD sources can be turned into WaveJSON via `vcd2wavedrom`. Install parsers with `pip install wavejson` or `npm install wavejson-parser`.
- **Typical final artifact:** SVG (once rendered), with schema validation against `schema.json`.

## Why
- **Reach for it when:** you want a standard, version-control-friendly, extensible waveform format decoupled from any single rendering tool — good as the durable source of truth that multiple converters can target.
- **Limitations:** no native rendering (always needs a parser/renderer), limited to digital timing, and no analog waveforms.
- **Relative to siblings:** WaveJSON is the *format*; WaveDrom is the reference *renderer* for it — emit WaveJSON when portability across tools matters, and hand it to WaveDrom to produce the actual SVG.

## Source
- Solution reference: `fim/solution/wavejson.md`
