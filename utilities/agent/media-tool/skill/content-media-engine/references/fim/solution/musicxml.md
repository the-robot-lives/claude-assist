# MusicXML — Standard Music Notation Interchange Format

MusicXML is the W3C-standardized, XML-based interchange format for digital sheet music.
It is not a renderer — it is a *document format* that 250+ applications (Finale, Sibelius,
MuseScore, Dorico, OSMD, music21) can import and export, preserving pitch, rhythm, layout,
lyrics, dynamics, and engraving detail. When an agent must emit portable notation that any
score program can open, MusicXML is the safe target.

**Current Version**: 4.0 (W3C Community Group)  **License**: W3C Community Final Spec / royalty-free
**Forms**: uncompressed `.musicxml`/`.xml`, compressed `.mxl` (zip)  **Schema**: XSD + DTD

## Official Resources & Documentation
- Site: https://www.musicxml.com/
- Spec (4.0): https://www.w3.org/2021/06/musicxml40/
- Element reference: https://www.w3.org/2021/06/musicxml40/musicxml-reference/
- GitHub (schema): https://github.com/w3c/musicxml
- Tutorial: https://www.musicxml.com/tutorial/

## Document Forms & Root Elements

MusicXML has two organizational modes; **`score-partwise`** (parts contain measures) is by
far the most common. `score-timewise` (measures contain parts) is rarely used.

### Minimal valid document
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
  "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
  <part-list>
    <score-part id="P1"><part-name>Music</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <note>
        <pitch><step>C</step><octave>4</octave></pitch>
        <duration>4</duration><type>whole</type>
      </note>
    </measure>
  </part>
</score-partwise>
```

## Core Element Reference

### Header: `part-list` / `score-part`
Declares instruments (parts) with IDs referenced by each `<part>`. Add `<part-abbreviation>`,
`<midi-instrument>`, and `<score-instrument>` for playback/labels.
```xml
<part-list>
  <score-part id="P1">
    <part-name>Violin</part-name>
    <part-abbreviation>Vln.</part-abbreviation>
    <midi-instrument id="P1-I1"><midi-program>41</midi-program></midi-instrument>
  </score-part>
</part-list>
```

### `attributes` — divisions, key, time, clef
`<divisions>` sets how many `<duration>` units equal one quarter note (the whole file's
rhythmic resolution). Only emit `<attributes>` when something changes (usually measure 1).
```xml
<attributes>
  <divisions>4</divisions>            <!-- 4 duration-units per quarter -->
  <key><fifths>2</fifths><mode>major</mode></key>   <!-- 2 sharps = D major -->
  <time><beats>3</beats><beat-type>4</beat-type></time>
  <clef><sign>F</sign><line>4</line></clef>          <!-- bass clef -->
</attributes>
```
`<fifths>`: position on the circle of fifths (−7…+7; negatives = flats). `<sign>`: `G`/`F`/
`C`/`percussion`/`TAB`.

### `note` — pitch, duration, type
The atomic element. `<duration>` is in divisions; `<type>` is the visual note value.
```xml
<note>
  <pitch>
    <step>F</step>          <!-- A B C D E F G -->
    <alter>1</alter>        <!-- -1 flat, 1 sharp, 2 double-sharp -->
    <octave>4</octave>      <!-- 4 = middle-C octave -->
  </pitch>
  <duration>2</duration>    <!-- in <divisions> units -->
  <type>eighth</type>       <!-- whole|half|quarter|eighth|16th|32nd|... -->
  <dot/>                    <!-- dotted; repeat for double dot -->
  <stem>up</stem>
  <accidental>sharp</accidental>   <!-- printed accidental (visual) -->
</note>
```

### Rests, chords, ties
```xml
<note><rest/><duration>4</duration><type>quarter</type></note>

<!-- Chord: first note normal, subsequent notes carry <chord/> -->
<note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration><type>quarter</type></note>
<note><chord/><pitch><step>E</step><octave>4</octave></pitch><duration>4</duration><type>quarter</type></note>

<!-- Tie: sounding (tie) + visual (tied) -->
<note>
  <pitch><step>G</step><octave>4</octave></pitch>
  <duration>4</duration><type>quarter</type>
  <tie type="start"/>
  <notations><tied type="start"/></notations>
</note>
```

### Beams, tuplets, slurs, articulations
```xml
<note>
  <pitch><step>C</step><octave>5</octave></pitch>
  <duration>2</duration><type>eighth</type>
  <beam number="1">begin</beam>          <!-- begin|continue|end -->
  <notations>
    <slur type="start" number="1"/>
    <articulations><staccato/></articulations>
    <tuplet type="start" bracket="yes"/>
  </notations>
</note>
```

### Directions (dynamics, tempo, text)
`<direction>` carries non-note events attached to a position in the measure.
```xml
<direction placement="below">
  <direction-type><dynamics><f/></dynamics></direction-type>
</direction>
<direction placement="above">
  <direction-type><words>Allegro</words></direction-type>
  <sound tempo="120"/>
</direction>
```

### Barlines, repeats, endings
```xml
<barline location="right">
  <bar-style>light-heavy</bar-style>       <!-- final barline -->
  <repeat direction="backward"/>            <!-- :| -->
  <ending number="1" type="start"/>
</barline>
```

### Lyrics
```xml
<note>
  <pitch><step>C</step><octave>4</octave></pitch>
  <duration>4</duration><type>quarter</type>
  <lyric number="1"><syllabic>single</syllabic><text>Sing</text></lyric>
</note>
```

## How-To (worked recipes)

### How to color notes for highlighting
Most elements accept a `color` attribute (`#RRGGBB` or `#AARRGGBB`). Renderers like OSMD honor it.
```xml
<note color="#C0392B">
  <pitch><step>C</step><octave>4</octave></pitch>
  <duration>4</duration><type>quarter</type>
  <notehead color="#2980B9">normal</notehead>
</note>
```

### How to write a two-part (SATB-style) score
Declare two `<score-part>`s and give each its own `<part>` block; align by measure number.
```xml
<part-list>
  <score-part id="P1"><part-name>Soprano</part-name></score-part>
  <score-part id="P2"><part-name>Bass</part-name></score-part>
</part-list>
<part id="P1"><measure number="1">
  <attributes><divisions>1</divisions><clef><sign>G</sign><line>2</line></clef></attributes>
  <note><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration><type>whole</type></note>
</measure></part>
<part id="P2"><measure number="1">
  <attributes><divisions>1</divisions><clef><sign>F</sign><line>4</line></clef></attributes>
  <note><pitch><step>C</step><octave>3</octave></pitch><duration>4</duration><type>whole</type></note>
</measure></part>
```

### How to set the rhythmic resolution correctly
Pick `<divisions>` = LCM of the note values you need. For music with sixteenths and triplets,
use 12 or 24 so every duration is an integer.
```xml
<attributes><divisions>12</divisions></attributes>
<!-- quarter = 12, eighth = 6, sixteenth = 3, eighth-triplet = 4 -->
```

### How to add a backup for a second voice on one staff
`<backup>` rewinds the time cursor so a second voice can be written in the same measure.
```xml
<note><voice>1</voice><pitch><step>E</step><octave>5</octave></pitch><duration>16</duration><type>whole</type></note>
<backup><duration>16</duration></backup>
<note><voice>2</voice><pitch><step>G</step><octave>4</octave></pitch><duration>16</duration><type>whole</type></note>
```

## Do's and Don'ts

### ✅ Do
- Set `<divisions>` once and make every `<duration>` a consistent multiple of it.
- Put `<attributes>` only where things change (measure 1, or at a key/time/clef change).
- Emit chords by tagging the 2nd+ notes with `<chord/>`, all sharing the first note's duration.
- Use both `<tie>` (sound) and `<tied>` (print) for ties; likewise `<slur>` in `<notations>`.
- Prefer `.mxl` (zipped) for distribution — files shrink dramatically.

### ❌ Don't
- Don't mismatch `<duration>` and `<type>` — `<duration>` drives timing/MIDI; `<type>` drives the drawn symbol; inconsistency corrupts playback and beaming.
- Don't forget `<alter>` for accidentals in `<pitch>` — the printed `<accidental>` alone doesn't change the sounding pitch.
- Don't reference a `part` id that has no matching `<score-part>`; the part won't render.
- Don't hand-edit `.mxl` as text — unzip, edit the inner `.xml`, rezip (keep the `META-INF/container.xml`).
- Don't assume every consumer supports every 4.0 feature; stick to core elements for maximum portability.

## Styling, Theming & Customization
- **Color**: `color` attribute on notes, noteheads, stems, beams, text (`#RRGGBB`).
- **Layout hints**: `<print>` with `<system-layout>`, `<staff-layout>`, `new-system`/`new-page`.
- **Fonts**: `font-family`, `font-size`, `font-weight` on `<words>`, `<lyric>`, credits.
- **Appearance**: `<defaults>` block sets `<scaling>`, `<page-layout>`, `<appearance>` (line widths, note sizes) globally.
- Rendering fidelity of style depends on the consumer (OSMD, Verovio, Finale differ).

## Advanced Features
- **Compressed `.mxl`**: zip containing the score `.xml` plus `META-INF/container.xml` pointing at it.
- **Multiple voices/staves** per part via `<voice>`, `<staff>`, and `<backup>`/`<forward>`.
- **Tablature** (`<clef><sign>TAB</sign></clef>` + `<technical><string>`/`<fret>`).
- **Percussion** via `<unpitched>` and `<instrument>` references.
- **Playback hints**: `<sound>`, `<midi-instrument>`, `<play>` control tempo/dynamics for players.

## Common Pitfalls & Troubleshooting
- **Wrong rhythm on import** → `<divisions>` inconsistent with `<duration>` values.
- **Missing accidental in sound** → set `<alter>`, not just `<accidental>`.
- **Part invisible** → `part id` has no matching `score-part` in `<part-list>`.
- **Chord split into melody** → forgot `<chord/>` on the stacked notes.
- **Encoding errors** → save as UTF-8; declare it in the XML prolog.
- **`.mxl` won't open** → malformed zip or missing `container.xml`.

## Integration Notes
- **Render in browser**: [osmd](osmd.md) (best), Verovio, or [music21j](music21j.md).
- **Produce it from**: MuseScore/Finale/Sibelius/Dorico export, [lilypond](lilypond.md) via `musicxml2ly`/`ly2musicxml`, or [music21j](music21j.md)/Python music21.
- **Convert to/from**: ABC (`xml2abc`/`abc2xml`), [mei](mei.md) (`meicvt`), [mnx](mnx.md) (emerging tools).

## Best For / Avoid For
`interchange`, `distribution`, `archival`, `cross-app`, `analysis-input`, `render-input` —
choose MusicXML whenever notation must move between programs or be rendered by a standard engine.
Avoid for: hand-authoring by humans (verbose — use [abcjs](abcjs.md)/[lilypond](lilypond.md)),
tiny payloads, or when a JSON-native pipeline strongly prefers [mnx](mnx.md).

## See Also
- [osmd](osmd.md) — primary browser renderer for MusicXML
- [music21j](music21j.md) — produce/analyze MusicXML in JS
- [mei](mei.md) — scholarly XML alternative
- [mnx](mnx.md) — JSON-based successor
- [lilypond](lilypond.md) — engraving import via `musicxml2ly`
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
