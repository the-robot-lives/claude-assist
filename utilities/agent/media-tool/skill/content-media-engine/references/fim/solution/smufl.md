# SMuFL — Standard Music Font Layout

SMuFL is the specification that maps musical symbols to a consistent set of Unicode
codepoints (in the Private Use Area, U+E000–U+F8FF) and defines the metadata a font must
publish for a layout engine to position glyphs correctly. It is *not* a renderer and carries
no notation logic — it standardizes which glyph lives at which codepoint and how big it is,
so that any SMuFL-compliant font (Bravura, Petaluma, Leipzig, Gonville, …) is interchangeable
under a rendering engine (Verovio, VexFlow, MuseScore, Dorico).

**Current Version**: SMuFL 1.4  **License**: Open standard (W3C Music Notation CG); reference font Bravura is SIL OFL
**Reference font**: Bravura (+ `bravura_metadata.json`)  **Codepoint range**: PUA U+E000–U+F8FF (~2900 glyphs)

## Official Resources & Documentation
- Site & spec: https://www.smufl.org/ , https://w3c.github.io/smufl/latest/
- Glyph tables (browse codepoints): https://www.smufl.org/version/latest/
- Bravura font + metadata: https://github.com/steinbergmedia/bravura
- Petaluma (handwritten): https://github.com/steinbergmedia/petaluma
- GitHub (spec): https://github.com/w3c/smufl

## How SMuFL Is Organized

SMuFL groups glyphs into named **ranges** (e.g. *Clefs*, *Noteheads*, *Individual notes*,
*Rests*, *Standard accidentals (12-EDO)*, *Time signatures*, *Dynamics*, *Articulation*,
*Barlines*). Each glyph has a canonical **name** (`gClef`, `noteheadBlack`, `accidentalFlat`)
mapped to a stable codepoint. Fonts ship a **metadata JSON** describing per-glyph anchors,
bounding boxes, and engraving defaults.

### Using a SMuFL font in the browser
```css
@font-face {
  font-family: 'Bravura';
  src: url('/fonts/Bravura.woff2') format('woff2'),
       url('/fonts/Bravura.otf')  format('opentype');
}
.music { font-family: 'Bravura'; font-size: 48px; line-height: 1; }
```

### Emitting glyphs by codepoint
```javascript
const SMUFL = {
  gClef:          '',   // treble clef
  fClef:          '',   // bass clef
  noteheadBlack:  '',   // filled notehead
  noteheadHalf:   '',   // open notehead
  accidentalFlat: '',
  accidentalSharp:'',
  accidentalNatural:'',
  restWhole:      '',
  restQuarter:    '',
  barlineSingle:  '',
  timeSig4:       '',   // digit "4" for time signatures
};
document.querySelector('.music').textContent = SMUFL.gClef + SMUFL.noteheadBlack;
```
Always confirm exact codepoints against the current glyph table — this list is a small,
commonly-used subset of ~2900.

## Font Metadata (`*_metadata.json`)

The metadata file is what turns a font of glyphs into something an engine can lay out. Key
sections:
```json
{
  "fontName": "Bravura",
  "fontVersion": "1.392",
  "engravingDefaults": {
    "staffLineThickness": 0.13,
    "stemThickness": 0.12,
    "beamThickness": 0.5,
    "legerLineThickness": 0.16
  },
  "glyphBBoxes": {
    "noteheadBlack": { "bBoxNE": [1.18, 0.5], "bBoxSW": [0.0, -0.5] }
  },
  "glyphsWithAnchors": {
    "noteheadBlack": {
      "stemUpSE": [1.18, 0.168],
      "stemDownNW": [0.0, -0.168]
    }
  }
}
```
- **`engravingDefaults`** — recommended line/stem/beam thicknesses (in staff spaces).
- **`glyphBBoxes`** — bounding box per glyph for spacing/collision.
- **`glyphsWithAnchors`** — attachment points (stem, cut-out, numeral) so stems and flags join correctly.
- **`glyphAdvanceWidths`**, **`ligatures`**, **`sets`** (stylistic alternates, e.g. small/optional glyphs).

## Glyph Range Highlights
- **Clefs** (`U+E050…`): gClef, fClef, cClef, percussion, TAB.
- **Noteheads** (`U+E0A0…`): black, half, whole, double-whole, x, diamond, slash.
- **Individual notes** (`U+E1D0…`): pre-composed notes with stems/flags.
- **Rests** (`U+E4E0…`): whole, half, quarter, eighth … 128th.
- **Accidentals** (`U+E260…`): flat, natural, sharp, double variants, plus microtonal ranges.
- **Time signatures** (`U+E080…`): digits, common/cut time.
- **Dynamics** (`U+E520…`): p, f, mf, sfz, hairpins-as-text where applicable.
- **Articulation** (`U+E4A0…`): staccato, accent, tenuto, marcato, fermata.
- **Instrument-specific**: string techniques, wind fingerings, guitar, percussion, handbells, etc.

## How-To (worked recipes)

### How to color and size music glyphs
Glyphs are text — style them with normal CSS `color`/`font-size` (in staff-space multiples).
```html
<span class="music" style="color:#c0392b; font-size:64px;">&#xE050;</span> <!-- red treble clef -->
<span class="music" style="color:#2980b9;">&#xE0A4;</span>                  <!-- blue notehead -->
```

### How to load font metadata and read a glyph's stem anchor
```javascript
const meta = await fetch('/fonts/bravura_metadata.json').then(r => r.json());
const anchor = meta.glyphsWithAnchors.noteheadBlack.stemUpSE; // [x, y] in staff spaces
// Multiply by (fontSizePx / 4) to convert staff spaces → pixels (4 spaces per staff height).
```

### How to look up a glyph name → codepoint at runtime
Use the official `glyphnames.json` (name → codepoint map) so you reference by name, not magic hex.
```javascript
const names = await fetch('/fonts/glyphnames.json').then(r => r.json());
const cp = names['gClef'].codepoint;          // "U+E050"
const char = String.fromCodePoint(parseInt(cp.slice(2), 16));
```

### How to swap fonts without changing code
Because names/codepoints are standardized, changing `font-family` from `Bravura` to
`Petaluma` re-styles the whole score (engraved → handwritten) with no glyph remapping.
```css
.music { font-family: 'Petaluma'; }  /* same codepoints, different look */
```

## Do's and Don'ts

### ✅ Do
- Reference glyphs by **name** via `glyphnames.json`, then resolve to codepoints — don't scatter magic `\uE0xx`.
- Load and use the font's `*_metadata.json` for anchors/bboxes — that's how stems, flags, and spacing align.
- Size in **staff spaces** (4 spaces = staff height) and scale to px; SMuFL metrics are staff-space relative.
- Keep font + its metadata versioned together; anchors are font-specific.
- Verify codepoints against the current SMuFL glyph table when in doubt.

### ❌ Don't
- Don't treat SMuFL as a renderer — it provides glyphs and metrics, not beaming/spacing/layout logic.
- Don't hard-code pixel offsets for stems/flags — read anchors from metadata so font swaps still align.
- Don't assume every font implements all ~2900 glyphs; check the font's coverage/`sets`.
- Don't use codepoints from a different font's private mapping — SMuFL exists precisely to avoid that.
- Don't forget `line-height: 1` and a large `font-size`; music glyphs overflow default line boxes.

## Styling, Theming & Customization
- **Look**: choose the font (Bravura = engraved reference, Petaluma = handwritten, Leipzig/Gonville = alternatives).
- **Color/size**: standard CSS on the glyph text.
- **Engraving defaults**: pull `staffLineThickness`, `stemThickness`, `beamThickness` from metadata to keep custom-drawn staff lines consistent with the font's weight.
- **Stylistic sets**: `sets` in metadata expose alternates (e.g. smaller noteheads, optional glyphs).

## Advanced Features
- **Anchors** enable precise composition of notehead + stem + flag + augmentation dot.
- **Ligatures** for multi-glyph constructs.
- **Optional/short flags, time-signature digits, tuplet numerals** as dedicated glyphs.
- **Microtonal and world-notation ranges** (Sagittal, Persian, etc.) for specialized repertoire.

## Common Pitfalls & Troubleshooting
- **Boxes/□ instead of glyphs** → font not loaded, wrong `font-family`, or PUA codepoint not in the font.
- **Stems/flags misaligned** → not using metadata anchors, or mixing metrics from a different font.
- **Glyph too small/clipped** → tiny `font-size` or `line-height` clipping; PUA glyphs need generous box.
- **Wrong symbol** → codepoint copied from a non-SMuFL legacy font (e.g. old Sonata/Maestro mappings).
- **Cross-browser rendering diffs** → subpixel hinting; test in target browsers.

## Commonly-Used Glyph Codepoints (subset)
Reference by name via `glyphnames.json`; these hex values are the canonical SMuFL mappings
for the most frequent symbols (always verify against the current version):

| Name | Codepoint | Symbol |
|------|-----------|--------|
| `gClef` | U+E050 | treble clef |
| `fClef` | U+E062 | bass clef |
| `cClef` | U+E05C | C clef |
| `timeSig0`…`timeSig9` | U+E080–E089 | time-signature digits |
| `noteheadBlack` | U+E0A4 | filled notehead |
| `noteheadHalf` | U+E0A3 | open notehead |
| `noteheadWhole` | U+E0A2 | whole notehead |
| `flag8thUp` | U+E240 | eighth-note flag (up) |
| `accidentalFlat` | U+E260 | flat |
| `accidentalNatural` | U+E261 | natural |
| `accidentalSharp` | U+E262 | sharp |
| `restWhole` | U+E4E3 | whole rest |
| `restQuarter` | U+E4E5 | quarter rest |
| `rest8th` | U+E4E6 | eighth rest |
| `barlineSingle` | U+E030 | single barline |
| `barlineFinal` | U+E032 | final barline |
| `dynamicPiano` (p) | U+E520 | dynamic p |
| `dynamicForte` (f) | U+E522 | dynamic f |

### Composing a notehead + stem manually (why anchors matter)
```javascript
const meta = await fetch('/fonts/bravura_metadata.json').then(r => r.json());
const spaces = 12;                       // px per staff space (font-size/4 with size=48)
const anchor = meta.glyphsWithAnchors.noteheadBlack.stemUpSE; // e.g. [1.18, 0.168]
const stemX = anchor[0] * spaces;        // where the stem attaches, in px
const stemY = -anchor[1] * spaces;
// Draw noteheadBlack at (0,0), then a vertical line up from (stemX, stemY).
// Without the anchor you'd guess the attach point and stems would float off the head.
```

## Integration Notes
- **Verovio** and modern **VexFlow** consume SMuFL fonts + metadata for rendering — you rarely touch codepoints directly when using them.
- Building a custom renderer: SMuFL metadata + a layout engine (yours) = a notation system. The glyphs are step one; spacing/beaming logic is step two.
- Font pipeline: ship `.woff2` for web, keep `.otf` + `*_metadata.json` + `glyphnames.json` together.
- **Font choices at a glance**: Bravura (engraved, reference), Petaluma (handwritten/jazz), Leipzig & Gonville (traditional alternatives), Leland (MuseScore 4), Sebastian, MuseJazz — all interchangeable under the standard.

## Best For / Avoid For
`custom-renderers`, `font-swapping`, `notation-engines`, `glyph-level-control`,
`professional-fonts` — choose SMuFL when you build or configure the rendering layer itself.
Avoid for: quick notation display where a full engine ([osmd](osmd.md), [vexflow](vexflow.md),
[abcjs](abcjs.md)) already bundles fonts and layout — use those instead of hand-placing glyphs.

## See Also
- [vexflow](vexflow.md) — supports pluggable SMuFL music fonts
- [mei](mei.md) — rendered by Verovio, which uses SMuFL fonts
- [musicxml](musicxml.md) — notation data that a SMuFL-based engine renders
- [lilypond](lilypond.md) — its Emmentaler font predates but parallels SMuFL concepts
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
