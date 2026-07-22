---
name: Gephi
description: Open-source desktop application for interactive visualization and exploration of networks
docs: https://gephi.org/users/
examples: https://github.com/gephi/gephi/wiki/Datasets
---

# Gephi — desktop network exploration + GEXF interchange

Gephi is a free desktop application (Java) for visualizing and exploring networks
interactively: you import a graph, run a force layout, compute statistics (communities,
centralities), style nodes and edges by those attributes in the Appearance panel, and
export a publication-quality image or a **GEXF** file for the web. For LLM-authoring the
two useful surfaces are (1) the **GEXF file format** Gephi reads and writes — a graph
interchange other tools (sigma.js via graphology, NetworkX) consume — and (2) the **Gephi
Toolkit** Java API for headless/programmatic pipelines. Gephi itself is a GUI, not
something you script inside a web page.

**Current Version**: Gephi 0.10.x (desktop); GEXF 1.3  **License**: GPL-3 / CDDL  **Runtime**: JVM desktop app (also "Gephi Lite" browser build); memory-heavy on large graphs

## Official Resources & Documentation
- Site: https://gephi.org/
- User docs & tutorials: https://gephi.org/users/
- GEXF format spec: https://gexf.net/
- Gephi Toolkit (Java): https://github.com/gephi/gephi-toolkit
- Gephi Lite (web): https://gephi.org/gephi-lite/
- Sample datasets: https://github.com/gephi/gephi/wiki/Datasets

## Installation & Setup

### Desktop
Download the installer from https://gephi.org/ (macOS/Windows/Linux). Requires a bundled
or system JDK. No package-manager install for the app itself.

### Gephi Toolkit (headless Java / Maven)
```xml
<dependency>
  <groupId>org.gephi</groupId>
  <artifactId>gephi-toolkit</artifactId>
  <version>0.10.1</version>
</dependency>
```

## Core Syntax / API Reference — the GEXF format
GEXF is the native graph interchange. This is what an LLM most often needs to *emit*:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<gexf xmlns="http://gexf.net/1.3" version="1.3">
  <meta lastmodifieddate="2026-07-09">
    <creator>npl-fim</creator>
    <description>Sample network</description>
  </meta>
  <graph mode="static" defaultedgetype="directed">
    <attributes class="node">
      <attribute id="0" title="category" type="string"/>
      <attribute id="1" title="score" type="float"/>
    </attributes>
    <nodes>
      <node id="a" label="Alpha">
        <attvalues>
          <attvalue for="0" value="infra"/>
          <attvalue for="1" value="0.82"/>
        </attvalues>
        <viz:color r="79" g="142" b="247" xmlns:viz="http://gexf.net/1.3/viz"/>
        <viz:size value="12" xmlns:viz="http://gexf.net/1.3/viz"/>
        <viz:position x="0" y="0" z="0" xmlns:viz="http://gexf.net/1.3/viz"/>
      </node>
      <node id="b" label="Beta"/>
    </nodes>
    <edges>
      <edge id="e0" source="a" target="b" weight="2.0"/>
    </edges>
  </graph>
</gexf>
```
Key points: nodes carry `id` + `label`; custom columns are declared once under
`<attributes>` and referenced by `for=` in each node's `<attvalues>`; the `viz:` namespace
carries render hints (`color`, `size`, `position`) that Gephi and sigma.js honor. Set
`defaultedgetype` to `directed` or `undirected`; per-edge `type=` overrides it.

### Other import/export formats
GraphML (`.graphml`), GDF (`.gdf`), Pajek (`.net`), CSV edge lists, and adjacency
matrices import via **File → Import**. Export images as SVG/PDF/PNG from the Preview tab.

### Gephi Toolkit (programmatic layout + export)
```java
ProjectController pc = Lookup.getDefault().lookup(ProjectController.class);
pc.newProject();
GraphModel gm = Lookup.getDefault().lookup(GraphController.class).getGraphModel();

Node n1 = gm.factory().newNode("a"); n1.setLabel("Alpha"); n1.setSize(12f);
Node n2 = gm.factory().newNode("b"); n2.setLabel("Beta");
gm.getGraph().addNode(n1); gm.getGraph().addNode(n2);
gm.getGraph().addEdge(gm.factory().newEdge(n1, n2, 1f, true));

ForceAtlas2 layout = new ForceAtlas2(null);   // or YifanHuLayout
layout.setGraphModel(gm); layout.initAlgo();
for (int i = 0; i < 200 && layout.canAlgo(); i++) layout.goAlgo();
layout.endAlgo();

ExportController ec = Lookup.getDefault().lookup(ExportController.class);
ec.exportFile(new File("out.gexf"));
```

## Layouts & Statistics (the interactive workflow)
- **Layouts**: ForceAtlas2 (the standard), Yifan Hu, Fruchterman-Reingold, OpenOrd
  (huge graphs), Circular, Radial Axis, Noverlap (overlap removal), Label Adjust.
- **Statistics** (Statistics panel): Modularity (community detection → a `Modularity Class`
  column), Betweenness/Closeness/Eigenvector centrality, PageRank, Degree, Average Path
  Length, Clustering Coefficient. These write node columns you then style by.

## How-To (worked recipes)

### How to color and size nodes & edges (Appearance panel)
The GUI workflow: **Appearance → Nodes → Color → Partition** to color by a categorical
column (e.g. `Modularity Class`), or **→ Ranking** to color/size by a numeric column
(e.g. `Degree`, `PageRank`). Choose a palette, click **Apply**. Repeat under **Size** to
scale nodes by a metric. Edges get color from source/target or a weight ranking.
```text
1. Statistics → Run "Modularity"  → creates Modularity Class column
2. Appearance → Nodes → Color → Partition → pick "Modularity Class" → Palette → Apply
3. Appearance → Nodes → Size  → Ranking   → pick "Degree" → min 10 / max 60 → Apply
4. Layout → ForceAtlas2 → Run (stop when stable)
5. Preview → tune labels/edges → Export SVG/PDF/PNG
```
To bake colors/sizes into a file for another tool, set them (or the `viz:` fields) and
**Export → GEXF** — sigma.js will render them directly.

### How to detect and visualize communities
Run **Modularity** in Statistics, then color nodes by **Partition → Modularity Class**.
Optionally run ForceAtlas2 with "LinLog mode" and "Stronger gravity" so communities separate.

### How to prepare a Gephi graph for the web (sigma.js)
Style in Gephi, **Export → Graph file → .gexf**, then in the browser parse it with
`graphology-gexf` and hand the graph to Sigma (see `sigma_js.md`). The `viz:position`,
`viz:color`, and `viz:size` survive the round-trip.

### How to filter a subgraph
Use the **Filters** panel: drag a Degree Range or Attribute/Partition filter onto the
query, adjust the range, and Gephi hides non-matching elements live before export.

### How to size edges by weight and curve them (Preview)
In the **Preview** tab, set "Edge → Rescale weight" to map edge `weight` to thickness,
toggle "Edge → Curved", and set edge color to "Original"/"Source"/"Target"/"Mixed". Click
**Refresh**, then **Export** (SVG for vector, PNG for raster). Preview settings only affect
the export, not the interactive workspace.

## Data Laboratory & Statistics
- **Data Laboratory** tab is a spreadsheet over the graph: edit node/edge attribute
  tables, add computed columns, merge columns, and search — useful for cleaning imported
  data before layout.
- **Statistics** (run these to create columns you then style by): Average Degree, Network
  Diameter (→ Betweenness/Closeness/Eccentricity), Graph Density, Modularity (→ community
  classes), PageRank, HITS, Connected Components, Clustering Coefficient, Eigenvector
  Centrality, Average Path Length. Each writes a node or edge column.

## Supported Import/Export Formats
| Format | Import | Export | Notes |
|--------|:------:|:------:|-------|
| GEXF (`.gexf`) | ✅ | ✅ | native; carries `viz:` render hints + dynamics |
| GraphML (`.graphml`) | ✅ | ✅ | interop with NetworkX/igraph/Cytoscape |
| GDF (`.gdf`) | ✅ | ✅ | CSV-like, easy to emit |
| Pajek (`.net`) | ✅ | ✅ | classic SNA format |
| CSV edge/matrix | ✅ | ✅ | via import wizard |
| SVG / PDF / PNG | — | ✅ | from the Preview tab (figures) |

## Do's and Don'ts

### ✅ Do
- Run **Modularity** before styling if you want community colors — it's what creates the partition column.
- Fix overlaps with the **Noverlap** or **Label Adjust** layout after ForceAtlas2, before export.
- Emit `viz:color`/`viz:size`/`viz:position` in GEXF when the target renderer (sigma.js) should reuse your styling.
- Use **OpenOrd** or ForceAtlas2 with "Approximate Repulsion" for graphs above ~50k nodes.

### ❌ Don't
- Don't expect to embed Gephi in a web page — it's a desktop app; for the browser use `sigma_js` (or Gephi Lite).
- Don't declare a GEXF attribute inline on a node — attribute *columns* must be declared once under `<attributes>` and only *values* go on nodes.
- Don't load million-edge graphs without raising the JVM heap (edit the `-J-Xmx` option) — Gephi is memory-hungry.
- Don't forget node `id`s must be unique and edge `source`/`target` must reference existing node ids, or import fails.

## Styling, Theming & Customization
- **Partition vs Ranking**: Partition = discrete colors per category; Ranking = a gradient/size scale over a numeric range. This is the core styling distinction in the Appearance panel.
- **Preview settings**: the Preview tab controls the *exported* look — edge thickness, curved vs straight, label font/color, node border, opacity — independently of the interactive view.
- **Palettes**: built-in qualitative and sequential palettes; custom colors per class are editable.
- **Labels**: toggle node labels in the toolbar; size them by attribute in Preview.

## Advanced Features
- **Timeline / dynamic graphs**: GEXF `mode="dynamic"` with `<spells>` supports time-varying networks and a timeline scrubber.
- **Plugins**: install from **Tools → Plugins** (extra layouts, importers, exporters, e.g. sigma.js exporter, GeoLayout).
- **Data Laboratory**: a spreadsheet view to edit node/edge tables directly and add columns.
- **Toolkit automation**: headless pipelines for batch layout + export via the Java API above.

## Dynamic graphs & the GDF format
GEXF `mode="dynamic"` adds time to a graph — nodes/edges appear and disappear over a
timeline you scrub in Gephi:
```xml
<graph mode="dynamic" timeformat="double" defaultedgetype="directed">
  <nodes>
    <node id="a" label="Alpha" start="0.0" end="5.0"/>   <!-- exists on [0,5] -->
    <node id="b" label="Beta"  start="2.0"/>
  </nodes>
  <edges>
    <edge source="a" target="b" start="2.0" end="4.0"/>
  </edges>
</graph>
```
GDF is a simpler CSV-like alternative that's easy to emit for quick imports:
```text
nodedef>name VARCHAR,label VARCHAR,color VARCHAR
a,Alpha,'79,142,247'
b,Beta,'224,96,126'
edgedef>node1 VARCHAR,node2 VARCHAR,weight DOUBLE
a,b,2.0
```

## Performance & Limits
- **Memory-bound**: the desktop app comfortably handles graphs up to hundreds of thousands of edges; millions need raised JVM heap (`-J-Xmx8g` in the config) and the **OpenOrd** layout.
- **Layout scaling**: ForceAtlas2 with "Approximate Repulsion" (Barnes-Hut) is the practical choice for large graphs; exact repulsion is O(n²).
- **Rendering vs Preview**: the interactive 3D view is fast; the **Preview** tab re-rasterizes for high-quality vector export and is slower — style there only at export time.
- **Gephi Lite** (browser) targets smaller graphs than the desktop app; use it for sharing, not million-edge analysis.

## Integration Notes
- **→ Web (sigma.js)**: the canonical handoff — style in Gephi, export GEXF, render with `graphology-gexf` + Sigma. `viz:` attributes survive.
- **↔ NetworkX / igraph**: both read/write GEXF and GraphML, so you can analyze in Python and visualize in Gephi (or vice-versa).
- **Toolkit in CI**: the Java Toolkit runs headless for automated layout → GEXF/PNG pipelines without opening the GUI.
- **Plugins**: install extra exporters/layouts via Tools → Plugins (e.g. sigma.js exporter, GeoLayout for lat/long, Circle Pack).

## Common Pitfalls & Troubleshooting
- **GEXF won't validate**: mismatched namespace version, or `attvalue for=` referencing an undeclared attribute id.
- **Colors don't export**: you styled in the interactive view but the Preview/GEXF didn't pick them up — apply in Appearance and re-run Preview.
- **Layout never settles**: lower ForceAtlas2 scaling / enable "Prevent Overlap"; large graphs need OpenOrd.
- **Out-of-memory on import**: raise JVM heap; consider filtering or sampling the graph first.

## Best For / Avoid For
`network-exploration`, `community-detection`, `research-visualization`, `gexf-authoring`, `publication-figures`, `interactive-analysis` — choose Gephi when a human is exploring a graph and you want a styled export.
Avoid for: in-browser/embedded rendering (use `sigma_js`), programmatic algorithm pipelines (use `networkx` / `igraph`), or automated CI image generation without the Toolkit.

## See Also
- `sigma_js.md` — renders Gephi's GEXF exports in the browser (via graphology-gexf).
- `networkx.md` / `igraph.md` — script-driven analysis and GEXF/GraphML I/O.
- `cytoscape_js.md` — interactive web graph library (also reads GraphML).
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
