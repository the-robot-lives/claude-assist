# WaveDrom

## What
WaveDrom is a JavaScript library that renders digital timing diagrams from JSON descriptions, producing SVG output. It is web-based (browser or Node CLI); the LLM emits a compact JSON signal spec and WaveDrom renders it, making it the go-to for hardware/protocol documentation embedded in web or Markdown.

## How
- **LLM emits:** a WaveDrom JSON signal spec — an object with a `signal` array of `{name, wave, data}` entries (e.g. `{"name": "clk", "wave": "p......"}`, `{"name": "data", "wave": "x.345x.", "data": ["D1","D2","D3"]}`) plus optional `config`, `head`, `foot`.
- **Render path:** in Node, `wavedrom.renderWaveForm(0, config)` returns an SVG string (install `npm install -g wavedrom-cli` or the `wavedrom` module); in the browser, embed a `<script type="WaveDrom">` block and call `WaveDrom.ProcessAll()`. PNG/PDF export goes through Puppeteer.
- **Typical final artifact:** SVG (native), or PNG/PDF via headless-browser export.

## Why
- **Reach for it when:** you need clean, version-control-friendly digital timing diagrams (clocks, SPI/I2C/UART, DDR/AXI, FSM transitions) from a simple text/JSON definition with direct browser and Markdown embedding.
- **Limitations:** digital signals only with limited analog support, no complex-protocol diagramming beyond waveforms, and a browser dependency for interactive editing.
- **Relative to siblings:** WaveDrom is the concrete renderer for the WaveJSON format and the most common realization of the digital-timing category — pick WaveDrom over tikz-timing when the target is web/SVG rather than a LaTeX document.

## Source
- Solution reference: `fim/solution/wavedrom.md`
- Nested use-case detail: `fim/solution/wavedrom/use-case/engineering-diagrams.md`
