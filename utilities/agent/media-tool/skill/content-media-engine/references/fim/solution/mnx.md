# MNX — Modern JSON-Based Music Notation (W3C draft)

MNX is the next-generation music-notation encoding under development by the W3C Music
Notation Community Group as the intended successor to MusicXML. It is **JSON-native**,
separates *global* timeline information (measures, time/key signatures) from *per-part*
content, and aims for cleaner semantics and easier programmatic manipulation than XML.
As of this writing the specification is a working draft — treat exact key names as
version-sensitive and validate against the current spec before shipping.

**Status**: W3C CG draft (evolving)  **License**: W3C Community Final Spec / open
**Form**: JSON (primary)  **Maturity**: pre-1.0 — limited tool support; verify field names against the live spec

## Official Resources & Documentation
- Spec (draft): https://w3c.github.io/mnx/docs/
- GitHub: https://github.com/w3c/mnx
- Community Group: https://www.w3.org/community/music-notation/
- Design rationale / by-example: https://w3c.github.io/mnx/docs/comparisons/
- Issues (track churn): https://github.com/w3c/mnx/issues

## Document Structure

An MNX document is a single JSON object under an `mnx` wrapper. The defining idea: a
**`global`** object holds the shared timeline (the list of measures with their time/key
signatures), and **`parts`** hold the actual notes, each part's measures aligning positionally
with `global.measures`.

### Illustrative document (draft shape — verify against spec)
```json
{
  "mnx": { "version": 1 },
  "global": {
    "measures": [
      { "time": { "count": 4, "unit": 4 }, "key": { "fifths": 0 } }
    ]
  },
  "parts": [
    {
      "name": "Piano",
      "measures": [
        {
          "sequences": [
            {
              "content": [
                { "type": "event", "duration": { "base": "quarter" },
                  "notes": [ { "pitch": { "step": "C", "octave": 4 } } ] },
                { "type": "event", "duration": { "base": "quarter" },
                  "notes": [ { "pitch": { "step": "E", "octave": 4 } } ] },
                { "type": "event", "duration": { "base": "half" },
                  "notes": [ { "pitch": { "step": "G", "octave": 4 } } ] }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Core Concept Reference

### `mnx` — document envelope
```json
{ "mnx": { "version": 1 } }
```
Declares the format version. The rest of the document (`global`, `parts`, and layout/`scores`)
sits as siblings under the top-level object.

### `global.measures` — the shared timeline
Each entry describes one measure's timeline-level attributes, applied to every part.
```json
"global": {
  "measures": [
    { "index": 1, "time": { "count": 3, "unit": 4 }, "key": { "fifths": 2 } },
    { "barline": { "type": "final" } }
  ]
}
```

### `parts[].measures[].sequences[].content[]` — events & notes
Content is an ordered list; an **event** carries a `duration` and one or more `notes`
(each with a `pitch` of `step`/`octave`, optional `alter`). Rests are events without notes.
```json
{ "type": "event", "duration": { "base": "eighth", "dots": 1 },
  "notes": [ { "pitch": { "step": "F", "octave": 4, "alter": 1 } } ] }
```
`duration.base`: `whole|half|quarter|eighth|16th|...`; `dots` for dotting. `pitch.alter`:
`+1` sharp, `-1` flat, `+2` double-sharp.

### Rests, chords, ties
```json
{ "type": "event", "duration": { "base": "quarter" } }         // rest = event, no notes
{ "type": "event", "duration": { "base": "quarter" },
  "notes": [ { "pitch": { "step": "C", "octave": 4 } },
             { "pitch": { "step": "E", "octave": 4 } },
             { "pitch": { "step": "G", "octave": 4 } } ] }      // chord = multiple notes
// ties are expressed by note-level "tie" targets referencing the next note (see spec)
```

## Design Goals vs MusicXML
- **JSON, not XML** — parses natively in JS/Python; no DOM boilerplate.
- **Global vs part separation** — measure-level timeline lives once in `global`, not repeated per part.
- **Explicit IDs & references** for connecting events, slurs, and layout.
- **Layout as a distinct concern** — a `scores`/layout layer describes visual arrangement separately from semantic content.
- **Extensibility** — designed to grow without the legacy constraints of MusicXML.

## How-To (worked recipes)

### How to parse and walk an MNX document in JS
```javascript
const doc = JSON.parse(mnxText);
const timeline = doc.global.measures;
for (const part of doc.parts) {
  part.measures.forEach((measure, mi) => {
    for (const seq of measure.sequences ?? []) {
      for (const item of seq.content ?? []) {
        if (item.type === 'event' && item.notes) {
          const p = item.notes[0].pitch;
          console.log(`m${mi + 1}:`, p.step + (p.alter ?? '') + p.octave, item.duration.base);
        }
      }
    }
  });
}
```

### How to generate a C-major scale programmatically
```javascript
const steps = ['C','D','E','F','G','A','B','C'];
const octaves = [4,4,4,4,4,4,4,5];
const content = steps.map((step, i) => ({
  type: 'event', duration: { base: 'quarter' },
  notes: [ { pitch: { step, octave: octaves[i] } } ]
}));
const mnx = {
  mnx: { version: 1 },
  global: { measures: [ { time: { count: 4, unit: 4 } }, { time: { count: 4, unit: 4 } } ] },
  parts: [ { name: 'Scale', measures: [ { sequences: [ { content: content.slice(0,4) } ] },
                                        { sequences: [ { content: content.slice(4) } ] } ] } ]
};
```

### How to interoperate during the transition
Keep MusicXML as the portable master and generate MNX alongside; convert MNX→MusicXML for
any consumer that doesn't yet read MNX.
```javascript
// Pseudocode: prefer MNX internally, fall back to MusicXML for export
const payload = consumerSupportsMnx ? toMnx(model) : toMusicXml(model);
```

### How to validate against a JSON Schema in your pipeline
Because MNX is JSON, standard JSON-Schema tooling guards against drift and typos.
```javascript
import Ajv from 'ajv';
const ajv = new Ajv({ allErrors: true });
const validate = ajv.compile(mnxSchema);          // schema from the spec repo
if (!validate(mnxDocument)) {
  console.error('MNX invalid:', validate.errors);  // catch renamed/missing fields early
}
```

### How to add time/key signature changes on the timeline
Signature changes live in `global.measures`, applied to every part at that measure index.
```json
"global": {
  "measures": [
    { "time": { "count": 4, "unit": 4 }, "key": { "fifths": 0 } },
    { "time": { "count": 3, "unit": 4 } },
    { "key": { "fifths": -3 } }
  ]
}
```

## Do's and Don'ts

### ✅ Do
- Pin and check `mnx.version`, and validate against the *current* draft — key names still change.
- Keep timeline data (time/key/measures) in `global`; keep notes in `parts`.
- Treat MNX as forward-looking; maintain a MusicXML export path for real-world compatibility.
- Use JSON Schema validation in your pipeline to catch drift early.
- Watch the GitHub issues/spec for renames before relying on any specific field.

### ❌ Don't
- Don't assume broad application support yet — few editors import/export MNX today.
- Don't hard-code field names as permanent; the draft evolves (this doc's shapes are illustrative).
- Don't duplicate global timeline data into each part — that's the pattern MNX exists to remove.
- Don't ship MNX as your only distribution format for public consumption yet.
- Don't confuse MNX with MusicXML's XML structure — they are different data models.

## Styling, Theming & Customization
- Visual styling is intended to live in the **layout/`scores`** layer (separate from semantic
  content), and via style/class references rather than inline attributes — consult the draft for
  the current styling model. For now, most rendering of MNX goes through experimental tooling.

## Advanced Features (planned/emerging)
- Clean **layout layer** decoupled from content (multiple visual scores from one semantic source).
- First-class **IDs and cross-references** for slurs, ties, beams, directions.
- JSON-schema-driven validation and tooling.
- Designed for programmatic transformation and web-native pipelines.

## Common Pitfalls & Troubleshooting
- **Spec drift** → the single biggest risk; a field that worked last quarter may be renamed. Validate.
- **No renderer** → you likely need to convert MNX→MusicXML and render with [osmd](osmd.md)/Verovio.
- **Ambiguous examples online** → many predate the current draft; trust the live spec repo.
- **Tooling gaps** → expect to write your own parse/generate helpers.

## Integration Notes
- Today, pair MNX with a MusicXML export path and render via the MusicXML ecosystem ([osmd](osmd.md), Verovio).
- Store MNX as a future-proof semantic master while deriving MusicXML/PDF for consumers.
- Monitor the W3C CG for reference implementations and converters as they land.

## Best For / Avoid For
`future-proofing`, `json-pipelines`, `web-native`, `experimental`, `research` — choose MNX
when you want the emerging standard and control your own tooling.
Avoid for: production interchange today (use [musicxml](musicxml.md)), scholarly editions
([mei](mei.md)), or anything needing turnkey rendering right now.

## See Also
- [musicxml](musicxml.md) — the current standard MNX aims to replace
- [mei](mei.md) — scholarly XML encoding
- [music21j](music21j.md) — model/transform music, emit interchange formats
- [osmd](osmd.md) — render via a MusicXML bridge
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
