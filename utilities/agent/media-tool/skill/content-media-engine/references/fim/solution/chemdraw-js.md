# ChemDraw JS & Web Chemistry Structure Rendering

"ChemDraw JS" is the commercial Revvity/PerkinElmer JavaScript structure editor,
but the practical open web stack for drawing molecules from text is **RDKit.js**
(SMILES → SVG + descriptors), **Ketcher** (full structure editor), **SmilesDrawer**
(lightweight 2D), and **3Dmol.js** (3D). The common *source* an agent emits is a
chemistry line notation — SMILES, SMARTS, MOL/SDF, or reaction SMILES — which
these tools render to SVG/canvas/WebGL.

**Editors**: ChemDraw JS (commercial), Ketcher (Apache-2.0), RDKit.js (BSD-3),
3Dmol.js (BSD-3)  **Input**: SMILES, SMARTS, InChI, MOL/SDF, reaction SMILES

## Official Resources & Documentation
- RDKit.js: https://github.com/rdkit/rdkit-js , https://www.rdkitjs.com/
- Ketcher: https://github.com/epam/ketcher , https://lifescience.opensource.epam.com/ketcher/
- 3Dmol.js: https://3dmol.csb.pitt.edu/ , https://github.com/3dmol/3Dmol.js
- SmilesDrawer: https://github.com/reymond-group/smilesDrawer
- ChemDraw JS (commercial): https://revvitysignals.com/products/research/chemdraw
- SMILES spec: http://opensmiles.org/

## Installation & Setup
```html
<!-- RDKit.js (open source, WASM) -->
<script src="https://unpkg.com/@rdkit/rdkit/dist/RDKit_minimal.js"></script>

<!-- Ketcher standalone editor -->
<script src="https://cdn.jsdelivr.net/npm/ketcher-standalone@latest/dist/ketcher.js"></script>

<!-- 3Dmol.js for 3D -->
<script src="https://3Dmol.org/build/3Dmol-min.js"></script>

<!-- ChemDraw JS (commercial license required) -->
<script src="chemdraw-js/chemdraw.js"></script>
<link rel="stylesheet" href="chemdraw-js/chemdraw.css">
```
npm: `npm i @rdkit/rdkit`, `npm i ketcher-standalone ketcher-react`, `npm i 3dmol`.

## Core Syntax / API Reference

### Line-notation source formats
```
SMILES      CCO                         ethanol
            c1ccccc1                     benzene (aromatic lowercase)
            CC(=O)O                      acetic acid
SMARTS      [OX2H]                       hydroxyl query pattern
InChI       InChI=1S/C2H6O/c1-2-3/h3H,2H2,1H3
MOL/SDF     multi-line V2000/V3000 connection table
RXN SMILES  CC(=O)O.OCC>>CC(=O)OCC.O    esterification (reactants>agents>products)
```

### RDKit.js — SMILES to SVG + properties
```javascript
initRDKitModule().then(function (RDKit) {
  const mol = RDKit.get_mol("CC(=O)Oc1ccccc1C(=O)O");   // aspirin
  document.getElementById('mol').innerHTML = mol.get_svg(300, 220);

  const d = JSON.parse(mol.get_descriptors());
  console.log(d.amw, d.NumHBD, d.NumHBA, d.CrippenClogP);

  mol.delete();                                          // free WASM memory
});
```
Key `mol` methods: `get_svg(w,h)`, `get_svg_with_highlights(json)`,
`get_descriptors()`, `get_morgan_fp(json)`, `get_inchi()`, `get_molblock()`,
`get_substruct_match(qmol)`, `generate_aligned_coords(template, json)`.
Query molecules: `RDKit.get_qmol("<SMARTS>")`. **Always call `.delete()`** on
`mol`/`qmol` — they are WASM objects, not GC'd.

### Ketcher — interactive editor
```javascript
const ketcher = new Ketcher.Ketcher({
  element: document.getElementById('editor'),
  staticResourcesUrl: '/ketcher/static/'
});
await ketcher.setMolecule("CCO");          // load SMILES or a MOL block
const smiles = await ketcher.getSmiles();  // read back (async!)
const mol    = await ketcher.getMolfile(); // MOL/SDF
const ket    = await ketcher.getKet();     // Ketcher native JSON
```

### 3Dmol.js — 3D structure
```javascript
const viewer = $3Dmol.createViewer('mol-3d', { backgroundColor: 'white' });
viewer.addModel(sdfOrPdbString, 'sdf');    // formats: pdb|sdf|mol2|xyz|cube
viewer.setStyle({}, { stick: { radius: 0.15 }, sphere: { scale: 0.3 } });
viewer.zoomTo();
viewer.render();
```

### SmilesDrawer — fast 2D canvas
```javascript
const drawer = new SmilesDrawer.Drawer({ width: 300, height: 220 });
SmilesDrawer.parse("C1CCCCC1", tree =>
  drawer.draw(tree, 'canvas-id', 'light'));   // theme: 'light' | 'dark'
```

## Output / Rendering Types
- **2D structure** — SVG (RDKit.js) or canvas (SmilesDrawer, Ketcher).
- **3D structure** — WebGL (3Dmol.js): stick/sphere/cartoon/surface.
- **Reactions** — reaction SMILES rendered as a scheme.
- **Descriptors** — MW, logP, H-bond donors/acceptors, TPSA, fingerprints.

## How-To (worked recipes)

### How to highlight a substructure with color (the "add color" recipe)
Match a SMARTS query, then pass the matched atoms/bonds and a color to
`get_svg_with_highlights`:
```javascript
initRDKitModule().then(RDKit => {
  const mol  = RDKit.get_mol("CC(=O)Oc1ccccc1C(=O)O");
  const qmol = RDKit.get_qmol("C(=O)O");                 // carboxyl/ester
  const match = JSON.parse(mol.get_substruct_match(qmol));
  const details = {
    atoms: match.atoms, bonds: match.bonds,
    highlightColour: [1, 0.6, 0.6],                      // RGB 0..1
    addStereoAnnotation: true, legend: "aspirin"
  };
  document.getElementById('mol').innerHTML =
    mol.get_svg_with_highlights(JSON.stringify(details));
  mol.delete(); qmol.delete();
});
```

### How to compute drug-likeness descriptors
```javascript
const mol = RDKit.get_mol("CC(=O)Oc1ccccc1C(=O)O");
const d = JSON.parse(mol.get_descriptors());
console.log({ mw: d.amw, logP: d.CrippenClogP, hbd: d.NumHBD,
             hba: d.NumHBA, tpsa: d.tpsa, rotb: d.NumRotatableBonds });
mol.delete();
```

### How to render a reaction scheme
```javascript
// Reaction SMILES: reactants > agents > products
const rxnSmiles = "CC(=O)O.OCC>>CC(=O)OCC.O";
const rxn = RDKit.get_rxn(rxnSmiles);                    // reaction object
document.getElementById('rxn').innerHTML = rxn.get_svg(500, 180);
rxn.delete();
```
(If your RDKit.js build lacks `get_rxn`, render reactants/products separately.)

### How to show a molecule in 3D from a MOL block
```javascript
const viewer = $3Dmol.createViewer('viewer', { backgroundColor: '#0b0b0b' });
viewer.addModel(await ketcher.getMolfile(), 'sdf');
viewer.setStyle({}, { stick: {}, sphere: { scale: 0.25 } });
viewer.zoomTo(); viewer.render();
```

### How to align a series to a common scaffold
```javascript
const templ = RDKit.get_mol("c1ccccc1");                 // benzene template
templ.set_new_coords();
const mol = RDKit.get_mol("Cc1ccccc1O");
mol.generate_aligned_coords(templ, JSON.stringify({ useCoordGen: true }));
document.getElementById('m').innerHTML = mol.get_svg(250, 200);
mol.delete(); templ.delete();
```

## Do's and Don'ts

### ✅ Do
- Prefer canonical SMILES; write aromatics lowercase (`c1ccccc1`) or use Kekulé
  form consistently.
- Call `.delete()` on every RDKit.js `mol`/`qmol`/`rxn` (WASM memory leaks).
- `await` Ketcher's async getters (`getSmiles`, `getMolfile`).
- Wait for `initRDKitModule()` to resolve before any `RDKit.*` call.
- Validate untrusted SMILES: `RDKit.get_mol` returns null-ish for invalid input.

### ❌ Don't
- Don't assume ChemDraw JS is available — it is commercial; default to RDKit.js.
- Don't call `RDKit.get_mol` before the WASM module has initialized.
- Don't forget substructure colors are RGB floats `0..1`, not 0–255 or hex.
- Don't mix up SMILES (a molecule) with SMARTS (a query) — queries go through
  `get_qmol`.
- Don't leave 3Dmol.js without a final `viewer.render()` — nothing appears.

## Styling, Theming & Customization
- **RDKit drawing options**: pass a JSON (a `MolDrawOptions`) to
  `get_svg_with_highlights` — keys like `addAtomIndices`, `addStereoAnnotation`,
  `bondLineWidth`, `legend`, `backgroundColour`, `highlightColour`,
  `highlightBondWidthMultiplier`.
- **SmilesDrawer themes**: `'light'` / `'dark'` (and custom theme objects).
- **3Dmol.js styles**: `stick`, `sphere`, `line`, `cartoon`, `surface`, each with
  color schemes (`colorscheme: 'Jmol'`, per-atom colors).
- **Ketcher**: editor look via its React theme; export format chosen per getter.

## Advanced Features
- **Fingerprints & similarity** (`get_morgan_fp`) for search/clustering.
- **Substructure/SMARTS matching** for highlighting and filtering.
- **InChI/InChIKey** generation for canonical identifiers.
- **Coordinate generation** (CoordGen) and scaffold alignment.
- **3D**: surfaces, measurements, and multi-model overlays in 3Dmol.js.
- **Server-side Indigo** via Ketcher's `structServiceProvider` for heavy ops.

## Common Pitfalls & Troubleshooting
- **Nothing renders / `RDKit is undefined`** → called before `initRDKitModule()`
  resolved.
- **Growing memory** → missing `.delete()` on WASM objects.
- **Blank 3D canvas** → forgot `zoomTo()`/`render()`, or bad model format string.
- **Wrong/empty structure** → invalid SMILES, or Kekulé/aromatic mismatch.
- **Highlight ignored** → color given as 0–255/hex instead of `0..1` floats, or
  atom indices from a different molecule than the one drawn.
- **Ketcher returns a Promise** → you didn't `await` the getter.

## Integration Notes
- RDKit.js and SmilesDrawer are pure client-side (WASM/JS) — embeddable anywhere.
- Ketcher can run standalone or against an Indigo backend for advanced features.
- For static docs, pre-render RDKit SVG server-side (Node) and inline the SVG.

## Best For / Avoid For
`chemistry`, `smiles`, `molecule-2d`, `molecule-3d`, `reactions`, `descriptors`
— choose RDKit.js for programmatic 2D + properties, 3Dmol.js for 3D, Ketcher for
editing. Avoid for non-chemistry diagrams and for typeset reaction *equations* in
papers (use LaTeX `mhchem`/`chemfig`).

## See Also
- [kicad.md](kicad.md) — unrelated EE sibling in this category
- [schemdraw.md](schemdraw.md) — other programmatic diagram source
- ../use-case/mathematical-scientific.md
- ../use-case/engineering-diagrams.md
