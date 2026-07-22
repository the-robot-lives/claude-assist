# @noizu/ithkuil-word

`<ithkuil-word>` — Lit custom element that renders New Ithkuil words from canonical coordinate tuples as compact or exploded SVG. Clever about presentation, deliberately stupid about Ithkuil: no romanization parsing, enum ranking, or integer arithmetic happens here.

## Quick start (no build)

```bash
cd web && python3 -m http.server 8080
# open http://localhost:8080/demo/
```

The demo resolves `lit` from a CDN via import map. In an app, `npm install lit` and import normally — source is plain ES modules (`src/*.js`) with types in `types.d.ts`.

## Usage

```html
<ithkuil-word
  coordinate='["ithkuil-word",1,[["glyph",0,17,1,[[1,["modifier",6,2,[3],[]]]]]]]'>
</ithkuil-word>
```

```js
import "@noizu/ithkuil-word";

// Hologram/production path: inject a full codec-computed render model
el.model = viewModel;

// Standalone path: hand it a coordinate; the bundled scene compiler runs locally
el.coordinate = ["ithkuil-word", 1, [...]];
el.latinized = "...";        // optional, codec-provided
el.integer = "93847598...";  // optional, unsigned DECIMAL STRING (never BigInt across the boundary)
```

| Property | Type | Notes |
|---|---|---|
| `model` | `IthkuilWordModel` | Precomputed render model; wins over `coordinate` |
| `coordinate` | wire array \| JSON string | Compiled locally via `compileScene` |
| `latinized` / `integer` | `string` | Optional codec facts, shown in the detail panel |
| `exploded` | `boolean`, reflected | Compact ⇄ exploded projection |

Interaction: click / Enter / Space toggles the view (emits composed `ithkuil-mode-change`); right-click / Shift+F10 opens the detail panel (copy coordinate, integer, SVG); hovering highlights the socket subtree; Escape closes the panel.

Methods: `el.toSVG(mode?)` returns a standalone SVG string with the coordinate embedded as metadata; `IthkuilWordElement.extractCoordinate(svgText)` recovers the tuple exactly from any SDK-generated SVG (returns `null` if metadata was stripped — that file then belongs to the deferred recognition subsystem).

## Module map

| Module | Role |
|---|---|
| `src/ithkuil-word.js` | The custom element (shadow DOM, interaction, theming via `--ithkuil-stroke` / `--ithkuil-accent`) |
| `src/scene.js` | Deterministic scene compiler: coordinate → flat node list, each node with stable ID + `compact`/`exploded` placements |
| `src/coordinate.js` | Wire-form validation + canonicalization (tagged arrays; sockets sorted, duplicates rejected) |
| `src/registry.js` | Seed enums + geometry — stand-in for codegen from `../spec/*.yaml`; placeholder paths are deterministic per ID until official glyph paths land |
| `src/metadata.js` | SVG export with embedded metadata + exact tuple recovery |

Exploded geometry follows the fixed-socket rule: every socket has a permanent angle (rotated with its parent's orientation); empty sockets draw nothing; occupied sockets never move. Marker at r=64, orbit box at r=118, radial connector from the exact center, all shrinking ×0.5 per recursion depth. One viewBox covers both projections so toggling never reflows.
