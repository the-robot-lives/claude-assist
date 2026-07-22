# SMuFL (Standard Music Font Layout)

## What
SMuFL is an open standard (from the W3C Music Notation Community Group) that maps musical symbols to Unicode Private-Use-Area codepoints and font glyphs, defining a comprehensive layout for music-notation fonts. It is a font/glyph-encoding standard, not a renderer. Its consumers are notation layout engines and any application drawing musical glyphs with a SMuFL-compliant font.

## How
- **LLM emits:** text/HTML using SMuFL codepoints together with a SMuFL font family — e.g. mapping `trebleClef: ''`, `quarterNote: ''`, `flat: ''` and setting `fontFamily: 'Bravura'`.
- **Render step:** load a SMuFL font via `@font-face` (e.g. `Bravura.otf`), set the font on the target element, and insert the glyph codepoints (`element.innerHTML = symbols.trebleClef + symbols.quarterNote`). SMuFL provides JSON metadata for glyph positioning; a layout engine is required to place glyphs into real notation.
- **Final artifact:** rendered musical glyphs/symbols (as text glyphs) — the raw building blocks of a score. Turning these into a laid-out score requires a separate notation engine; SMuFL supplies glyphs, not notation intelligence.

## Why
- **Reach for it when:** you are building a score-rendering system, notation app, or music-theory/education tool and need consistent, professional glyphs that work across any compliant font — e.g. Bravura (reference), Petaluma (handwritten), Leipzig (traditional). 2400+ symbols standardized with font independence and metadata support.
- **Limitations:** a renderer/layout engine is required (SMuFL is just glyphs); large font files (~500KB–1MB); spacing/positioning must be calculated; only a few complete SMuFL fonts exist; no built-in notation logic.
- **Relative to siblings:** SMuFL sits a layer below the renderers — it is the glyph standard that engines like VexFlow, OSMD, and Verovio rely on to draw symbols. It is not an alternative to those tools; it is the font foundation they consume.

## Source
- Solution reference: `fim/solution/smufl.md`
