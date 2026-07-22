# Electronics / HDL / Timing + Image-Video + Document-File Processing

This category groups three distinct sub-domains that share a common FIM pattern: the LLM emits a text spec, code, or command sequence, and a downstream engine turns it into a concrete artifact. It spans circuit/schematic/timing-diagram tooling (LaTeX packages, native EDA apps, Python analyzers, JSON waveform specs), image and video pipelines (browser WASM and Node.js libraries), and document/spreadsheet file conversion (DOCX/PDF/XLSX read and write). Consumers range from LaTeX toolchains and native desktop apps to browser JavaScript and Node.js runtimes.

## Solutions

#### Electronics / HDL / Timing

### CircuiTikZ
A LaTeX package extending TikZ for publication-quality circuit schematics; the LLM emits `circuitikz` environment markup that compiles to PDF (or SVG via conversion). Pick it when the circuit must live inside a typeset LaTeX document with matching typography and inline math. [Detail](electronics-media-docfile/circuitikz.md)

### Fritzing
An open-source visual EDA desktop app with breadboard, schematic, and PCB views, exporting SVG/PNG/PDF/Gerber. It's the maker/education counterpart to KiCad — reach for it for approachable breadboard diagrams and simple-to-medium boards rather than dense professional layouts. [Detail](electronics-media-docfile/fritzing.md)

### KiCad
A professional open-source EDA suite for schematic capture and PCB design with a `pcbnew` Python API, producing Gerber/STEP/VRML/SVG. Choose it when the deliverable is a fabricable multi-layer board rather than a document graphic. [Detail](electronics-media-docfile/kicad.md)

### Lcapy
A Python package for symbolic linear-circuit analysis on SymPy, emitting transfer functions, LaTeX equations, and schematics from an inline netlist. Pick it over PySpice when you want closed-form symbolic results rather than numeric simulation. [Detail](electronics-media-docfile/lcapy.md)

### PySpice
A Python interface to SPICE simulators (Ngspice/Xyce) with unit-aware element construction and matplotlib plotting. The numeric-simulation counterpart to Lcapy's symbolic analysis; reach for it for DC/AC/transient/noise runs and sweeps. [Detail](electronics-media-docfile/pyspice.md)

### SchemDraw
A pure-Python schematic-drawing library with a flow-based API and matplotlib backend, exporting SVG/PNG/PDF. The programmatic analogue to CircuiTikZ — use it to generate schematics from code outside a LaTeX document. [Detail](electronics-media-docfile/schemdraw.md)

### SPICE Netlist
The industry-standard plain-text circuit-description format consumed by every SPICE engine; the LLM emits element lines, analysis directives, and subcircuits. Hand-author it for maximum simulator portability; it renders no schematic itself. [Detail](electronics-media-docfile/spice-netlist.md)

### Verilog Diagrams
A Yosys→netlistsvg / pyverilog toolchain that visualizes RTL structure as schematics, hierarchy, and dataflow graphs (SVG/DOT/JSON). Renders the *structure* of HDL, complementary to WaveDrom's *timing behavior*. [Detail](electronics-media-docfile/verilog-diag.md)

### Digital Timing Diagrams
An umbrella category of timing-diagram tools/formats (tikz-timing, WaveDrom, Python) for protocol and bus visualization across LaTeX, web, and Python toolchains. In practice, pick a concrete tool — usually WaveDrom or tikz-timing — matched to your output pipeline. [Detail](electronics-media-docfile/digital-timing.md)

### WaveDrom
A JavaScript library rendering digital timing diagrams from a JSON signal spec to SVG (PNG/PDF via headless browser). The most common realization of the digital-timing category and the reference renderer for WaveJSON; pick it for web/Markdown-embedded waveforms. [Detail](electronics-media-docfile/wavedrom.md)

### WaveJSON
The tool-agnostic JSON format for waveform descriptions — the portable source of truth that WaveDrom and other converters consume. Emit it when portability across tools matters; hand it to WaveDrom to produce the actual SVG. [Detail](electronics-media-docfile/wavejson.md)

#### Image & Video Processing

### FFmpeg.wasm
A WebAssembly port of FFmpeg running full video/audio processing in the browser; the LLM emits familiar FFmpeg argument arrays. The time-based-media powerhouse of this group and privacy-first (media never leaves the device), at the cost of a ~30MB core and 2–10x-slower-than-native speed. [Detail](electronics-media-docfile/ffmpeg-wasm.md)

### Jimp
A pure-JavaScript, zero-dependency image library with a chainable API that runs in Node and the browser. The portability side of the Jimp/Sharp tradeoff — runs anywhere including serverless, but slower than native bindings. [Detail](electronics-media-docfile/jimp.md)

### Sharp
A high-performance Node.js image library built on libvips, chaining resize/convert/composite operations to optimized rasters. The native-binding speed choice for server-side pipelines and batch optimization; Node-only. [Detail](electronics-media-docfile/sharp.md)

### node-canvas
A Cairo-backed HTML Canvas API implementation for Node.js, used to *draw and composite* images from scratch server-side (PNG/JPEG/PDF/SVG). Reach for it when the pixels don't exist yet, versus Sharp/Jimp which transform existing images. [Detail](electronics-media-docfile/node-canvas.md)

#### Document-File Processing

### Mammoth.js
A JS library converting Word DOCX to clean, semantic HTML with customizable style maps, in Node and the browser. The *ingestion* end of the document group — one-way DOCX→HTML for imports, migrations, and CMS workflows. [Detail](electronics-media-docfile/mammoth_js.md)

### PDF.js
Mozilla's browser-side PDF viewer/parser, rendering pages to canvas with text extraction, search, and form support. It *consumes* PDFs (view/extract), the mirror image of the pdfkit/jsPDF generators. [Detail](electronics-media-docfile/pdf_js.md)

### PDFKit
A programmatic PDF-generation library for Node and browsers with rich vector graphics and font embedding via a streaming model. Leans server-side with more capability than jsPDF; use it for reports, invoices, and dynamic-data documents. [Detail](electronics-media-docfile/pdfkit.md)

### jsPDF
A lightweight, browser-first PDF generator building documents from imperative text/shape/image calls and triggering a download. The client-side counterpart to PDFKit, and the required dependency underneath svg2pdf.js. [Detail](electronics-media-docfile/jspdf.md)

### SheetJS
The `xlsx` library for parsing and writing spreadsheets (XLSX/XLS/CSV/ODS and 20+ formats) in browser and Node, bridging spreadsheets and JSON. The tabular-data member of the group — Excel import/export, conversion, and report generation. [Detail](electronics-media-docfile/sheetjs.md)

### svg2pdf.js
A jsPDF-based library converting SVG DOM elements to PDF while preserving vector graphics and selectable text. The SVG-specialized bridge on top of jsPDF; use it when the source is already SVG and vector fidelity matters. [Detail](electronics-media-docfile/svg2pdf.md)

## Source
- Per-solution detail files: `fim/overview/electronics-media-docfile/{solution}.md` (21 files)
