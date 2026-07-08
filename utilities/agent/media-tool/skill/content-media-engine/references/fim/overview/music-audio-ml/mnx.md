# MNX (Music Notation eXtensible)

## What
MNX is the next-generation music-notation format from the W3C Music Notation Community Group, positioned as the future successor to MusicXML. It is a JSON-based (with XML alongside) score-encoding format emphasizing modern web technologies, semantic clarity, and extensibility. Its consumer is a browser/web application parsing the structure; it is a format, not a renderer.

## How
- **LLM emits:** an MNX JSON document — a top-level `"mnx"` object with `version` and a `score` containing `parts` → `measures` → `sequences` → `content` events, each event carrying a `duration` and `notes` with `pitch` (`octave`, `step`).
- **Render step:** parse the MNX JSON/XML structure, extract musical elements and metadata, then hand off to a rendering pipeline. Note the format is still an evolving W3C draft, so implementation support is limited.
- **Final artifact:** engraved notation produced downstream by whatever renderer consumes the parsed structure; MNX itself is the encoding, optimized for web-native/browser consumption.

## Why
- **Reach for it when:** you are future-proofing a notation project, need native JSON encoding for web apps, want an extensible schema for custom growth, or are doing research/experimental notation work.
- **Limitations:** early development — the specification is still evolving; few applications currently implement it; limited MusicXML→MNX conversion tools; reference documentation still being developed.
- **Relative to siblings:** MNX is the designated modern replacement for MusicXML — cleaner, JSON-native, more semantically explicit — but it is not yet production-ready. Today MusicXML remains the interoperable choice; MNX is where the standard is heading. Plan for hybrid MusicXML/MNX support during the transition.

## Source
- Solution reference: `fim/solution/mnx.md`
