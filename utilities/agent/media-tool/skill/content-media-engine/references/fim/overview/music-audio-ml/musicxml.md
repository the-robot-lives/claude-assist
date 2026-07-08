# MusicXML

## What
MusicXML is the industry-standard, W3C-standardized open XML format for exchanging digital sheet music. It is an interchange format (not a renderer) with comprehensive notation coverage, supported by 250+ applications including Finale, Sibelius, and MuseScore. Its consumers are notation software and renderer/parser libraries.

## How
- **LLM emits:** a MusicXML document — a `<score-partwise>` root containing `<part>` elements, each with `<measure>` elements holding `<attributes>` (divisions, key, time) and `<note>` elements carrying `<pitch>` (`<step>`, `<octave>`), `<duration>`, and `<type>`.
- **Render step:** hand the XML to a consumer — OSMD (OpenSheetMusicDisplay) is the JavaScript renderer, music21 the Python analysis toolkit; xml2abc converts to ABC, and various `musicxml-parser` implementations exist across languages.
- **Final artifact:** engraved sheet music once rendered (e.g. SVG via OSMD), or an imported score inside notation software; MusicXML itself preserves layout/formatting for faithful round-tripping.

## Why
- **Reach for it when:** interoperability is the goal — notation-software interchange, digital sheet-music distribution, analysis/education, archival/preservation, and cross-platform sharing. Its strength is near-universal support and complete, standardized notation representation.
- **Limitations:** verbose XML syntax; large file sizes for complex scores; overkill for simple use cases; requires parsing to manipulate.
- **Relative to siblings:** MusicXML is the lingua franca of the category — the format most renderers (OSMD), toolkits (music21/music21j), and editors consume and emit. MEI is its scholarly-metadata-rich cousin and MNX its designated JSON successor, but MusicXML remains the safe interchange default today.

## Source
- Solution reference: `fim/solution/musicxml.md`
