# MEI (Music Encoding Initiative)

## What
MEI is an XML-based format for encoding music notation together with rich scholarly metadata. It is a document format (not a renderer) designed for academic music research, digital critical editions, and musicological analysis. Its primary consumer is a rendering/analysis engine — chiefly Verovio — plus editing and library tooling.

## How
- **LLM emits:** an MEI XML document — `<mei>` with a `<meiHead>` (title/metadata) and a `<music><body><mdiv><score>` tree containing `<scoreDef>`, `<staffGrp>`/`<staffDef>`, `<section>`, `<measure>`, `<staff>`, `<layer>`, and `<note>` elements (e.g. `<note pname="c" oct="4" dur="4"/>`).
- **Render step:** feed the MEI to a rendering engine — Verovio is the primary one (`render_with: verovio`). Supporting tools include mei-friend (web editor), LibMEI (C++ manipulation), and online MEI viewers.
- **Final artifact:** engraved sheet music (Verovio typically emits SVG); the encoding itself also carries scholarly apparatus (variants, editorial marks, annotations, source/performer metadata) for analysis rather than only display.

## Why
- **Reach for it when:** scholarship is the point — digital-humanities projects, critical editions with variant/apparatus encoding, musicological research databases, historical archives, and academic publishing. It encodes semantics beyond visual notation and integrates with TEI for text.
- **Limitations:** steep learning curve for complex features; limited mainstream software support; primarily academic focus limits commercial adoption; verbose XML for simple scores.
- **Relative to siblings:** MEI is the scholarly-encoding counterpart to MusicXML. MusicXML is the interchange standard optimized for moving scores between notation apps; MEI trades broad software support for far richer editorial/critical metadata, so reach for MEI when the metadata and variants matter more than app interoperability.

## Source
- Solution reference: `fim/solution/mei.md`
