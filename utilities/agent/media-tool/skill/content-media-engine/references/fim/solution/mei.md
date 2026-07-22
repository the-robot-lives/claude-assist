# MEI — Music Encoding Initiative (Scholarly XML)

MEI is an XML format for encoding music notation together with rich scholarly and editorial
metadata — variant readings, editorial marks, source descriptions, and analytical layers.
Where MusicXML optimizes for interchange between engraving programs, MEI optimizes for
*critical editions and musicology*: it can represent what different sources say, who edited
what, and why. Its reference renderer is **Verovio**, which turns MEI (and MusicXML) into SVG.

**Current Version**: MEI 5.x (Basic/CMN/Neumes/Mensural/Analysis modules)  **License**: Educational Community License 2.0
**Form**: XML (`.mei`)  **Reference renderer**: Verovio (SVG, WASM/JS/Python)

## Official Resources & Documentation
- Site: https://music-encoding.org/
- Guidelines: https://music-encoding.org/guidelines/
- Schema/source: https://github.com/music-encoding/music-encoding
- Verovio (renderer): https://www.verovio.org/
- mei-friend (web editor): https://mei-friend.mdw.ac.at/
- Sample encodings: https://github.com/music-encoding/sample-encodings

## Document Structure

An MEI file has two halves: **`<meiHead>`** (metadata — the scholarly apparatus) and
**`<music>`** (the notation, nested `mdiv → score → section → measure → staff → layer`).

### Minimal document
```xml
<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0">
  <meiHead>
    <fileDesc>
      <titleStmt><title>Prelude</title></titleStmt>
      <pubStmt/>
    </fileDesc>
  </meiHead>
  <music>
    <body>
      <mdiv>
        <score>
          <scoreDef meter.count="4" meter.unit="4" key.sig="0">
            <staffGrp>
              <staffDef n="1" lines="5" clef.shape="G" clef.line="2"/>
            </staffGrp>
          </scoreDef>
          <section>
            <measure n="1">
              <staff n="1">
                <layer n="1">
                  <note pname="c" oct="4" dur="4"/>
                  <note pname="d" oct="4" dur="4"/>
                  <note pname="e" oct="4" dur="2"/>
                </layer>
              </staff>
            </measure>
          </section>
        </score>
      </mdiv>
    </body>
  </music>
</mei>
```

## Core Element Reference

### `scoreDef` / `staffDef` — global & per-staff setup
Attributes (not child elements) carry meter, key, and clef.
```xml
<scoreDef meter.count="3" meter.unit="4" key.sig="2s">
  <staffGrp symbol="brace">
    <staffDef n="1" lines="5" clef.shape="G" clef.line="2"/>
    <staffDef n="2" lines="5" clef.shape="F" clef.line="4"/>
  </staffGrp>
</scoreDef>
```
`key.sig`: `0`, `1s`…`7s` (sharps), `1f`…`7f` (flats). `clef.shape`: `G`/`F`/`C`.

### `note` — pitch, octave, duration, accidental
```xml
<note pname="f" oct="4" dur="8" accid="s"/>   <!-- F#4 eighth (sounding+written) -->
<note pname="b" oct="3" dur="4" accid.ges="f"/> <!-- gestural (sounding) flat, unprinted -->
<note pname="c" oct="5" dur="4" dots="1"/>       <!-- dotted quarter -->
```
`accid` = printed accidental; `accid.ges` = gestural (heard) accidental. This split is core
to MEI's editorial precision.

### `rest`, `chord`, `beam`, `tuplet`
```xml
<rest dur="4"/>
<chord dur="2">
  <note pname="c" oct="4"/><note pname="e" oct="4"/><note pname="g" oct="4"/>
</chord>
<beam>
  <note pname="c" oct="5" dur="8"/><note pname="d" oct="5" dur="8"/>
</beam>
<tuplet num="3" numbase="2">
  <note pname="c" oct="4" dur="8"/><note pname="d" oct="4" dur="8"/><note pname="e" oct="4" dur="8"/>
</tuplet>
```

### Control events (slurs, ties, dynamics, hairpins)
These sit inside `<measure>` and reference notes by `@startid`/`@endid` (xml:id), decoupling
them from the note stream.
```xml
<note xml:id="n1" pname="c" oct="4" dur="4"/>
<note xml:id="n2" pname="e" oct="4" dur="4"/>
<slur startid="#n1" endid="#n2"/>
<tie startid="#n1" endid="#n2"/>
<dynam startid="#n1" place="below">p</dynam>
<hairpin startid="#n1" endid="#n2" form="cres"/>
```

### Editorial & critical apparatus (MEI's distinguishing layer)
```xml
<app>                          <!-- variant readings across sources -->
  <lem source="#A"><note pname="c" oct="5" dur="4"/></lem>   <!-- lemma (chosen) -->
  <rdg source="#B"><note pname="d" oct="5" dur="4"/></rdg>   <!-- alternate reading -->
</app>
<choice>
  <corr>c</corr><sic>d</sic>   <!-- editorial correction vs. source error -->
</choice>
<supplied reason="illegible"><note pname="g" oct="4" dur="4"/></supplied>
```

## Supported Repertoires (modules)
- **CMN** — Common Music Notation (standard staff notation).
- **Mensural** — Renaissance mensural notation.
- **Neumes** — plainchant/Gregorian neumes.
- **Analytical** — harmonic/formal analysis annotations.
- **Facsimile** — link encoded notation to page images/zones.
- **MEI Basic** — a simplified interoperable subset for tooling.

## How-To (worked recipes)

### How to color notes for rendering
Use `@color` (Verovio honors CSS color values); pair with `xml:id` for CSS/JS targeting.
```xml
<note xml:id="hl1" pname="c" oct="4" dur="4" color="#C0392B"/>
<note pname="e" oct="4" dur="4" color="rgb(41,128,185)"/>
```

### How to render MEI to SVG with Verovio (browser)
```javascript
import createVerovioModule from 'verovio/wasm';
import { VerovioToolkit } from 'verovio/esm';

const VerovioModule = await createVerovioModule();
const tk = new VerovioToolkit(VerovioModule);
tk.loadData(meiXmlString);
document.getElementById('score').innerHTML = tk.renderToSVG(1); // page 1
```

### How to encode a variant reading between two sources
```xml
<app>
  <lem source="#autograph"><note pname="a" oct="4" dur="4"/></lem>
  <rdg source="#firstEdition"><note pname="g" oct="4" dur="4"/></rdg>
</app>
```

### How to attach analytical harmony to a measure
```xml
<measure n="5">
  <staff n="1"><layer n="1"><note pname="g" oct="3" dur="1"/></layer></staff>
  <harm staff="1" tstamp="1">V7</harm>   <!-- Roman-numeral / functional harmony -->
</measure>
```

### How to add lyrics (verse) under notes
Syllables attach via `<verse>` → `<syl>` inside the note, with `@con` for hyphenation.
```xml
<note pname="c" oct="4" dur="4">
  <verse n="1"><syl wordpos="i" con="d">Glo</syl></verse>   <!-- word-initial, dashed -->
</note>
<note pname="d" oct="4" dur="4">
  <verse n="1"><syl wordpos="t">ri</syl></verse>            <!-- word-terminal -->
</note>
```

### How to control Verovio rendering options
```javascript
tk.setOptions({
  scale: 40,                 // overall size
  pageWidth: 2100, pageHeight: 2970,
  font: 'Leipzig',           // Bravura | Leipzig | Petaluma | Gootville
  adjustPageHeight: true,
  breaks: 'auto',            // line-break strategy
  spacingStaff: 12,
});
tk.loadData(meiXmlString);
document.getElementById('score').innerHTML = tk.renderToSVG(1);
```

## Do's and Don'ts

### ✅ Do
- Give notes `xml:id`s so control events (`slur`, `tie`, `dynam`) can reference them by `@startid`/`@endid`.
- Use `accid` for printed accidentals and `accid.ges` for the sounding pitch when they differ.
- Encode meter/key/clef as *attributes* on `scoreDef`/`staffDef`, not child elements.
- Choose the smallest module set you need (MEI Basic for interoperability, add modules for scholarship).
- Render/validate with Verovio early — it is the de-facto conformance check.

### ❌ Don't
- Don't treat MEI like MusicXML structurally — control events are attribute-linked, not inline in the note stream.
- Don't omit the namespace `xmlns="http://www.music-encoding.org/ns/mei"` — tools reject it.
- Don't expect broad DAW/engraver import — support is mostly scholarly tooling + Verovio.
- Don't hand-encode large works without an editor (mei-friend) — the verbosity is punishing.
- Don't confuse `@dur` values (`1`=whole, `2`=half, `4`=quarter, `8`=eighth…) with MusicXML's word types.

## Styling, Theming & Customization
- **Color**: `@color` on notes/elements (Verovio → CSS color on SVG).
- **Verovio options**: JSON options control spacing, scale, page size, font (`--font Leipzig|Bravura|Petaluma`), and appearance.
- **CSS on SVG**: Verovio emits classed SVG (`.note`, `.staff`, ids) you can restyle in the DOM.
- **`<rend>`** elements style text (fonts, weight) in titles and directives.

## Advanced Features
- **Critical apparatus** (`app`/`lem`/`rdg`), corrections (`choice`/`corr`/`sic`), `supplied`, `unclear`.
- **Facsimile linking** — bind notation to manuscript image regions (`<zone>`, `@facs`).
- **Genetic/versioned encoding** for compositional stages.
- **TEI integration** for encoding sung text and prose alongside music.
- **Neumes/mensural** modules for pre-modern repertoire.

## Common Pitfalls & Troubleshooting
- **Verovio renders blank** → wrong/missing namespace or `meiversion`; validate against the RNG schema.
- **Slur/tie ignored** → `@startid`/`@endid` don't match note `xml:id`s (note the leading `#`).
- **Accidental sounds wrong** → set `accid.ges`; `accid` only prints the symbol.
- **Module errors** → element belongs to a module not included in your customization (use a full MEI schema or MEI Basic appropriately).
- **Huge files** → expected for critical editions; use an editor and XML tooling, not text editing.

## Integration Notes
- **Verovio** (WASM/JS/Python/CLI) is the standard renderer and MusicXML↔MEI bridge (`tk.getMEI()`, loads MusicXML too).
- **Conversion**: MusicXML→MEI via Verovio or `musicxml2mei`; MEI is often the archival master with MusicXML/PDF as derivatives.
- **Digital humanities** stacks combine MEI + TEI + IIIF image servers.

## Best For / Avoid For
`critical-editions`, `musicology`, `digital-humanities`, `archival`, `variant-encoding`,
`neumes-mensural`, `scholarly` — choose MEI when editorial/source fidelity is the point.
Avoid for: quick interchange with DAWs/engravers (use [musicxml](musicxml.md)), lightweight
web notation ([abcjs](abcjs.md)/[vexflow](vexflow.md)), or JSON-native pipelines ([mnx](mnx.md)).

## See Also
- [musicxml](musicxml.md) — mainstream interchange counterpart
- [mnx](mnx.md) — modern JSON-based encoding effort
- [smufl](smufl.md) — the music-font standard Verovio uses
- [lilypond](lilypond.md) — engraving for critical-edition output
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
