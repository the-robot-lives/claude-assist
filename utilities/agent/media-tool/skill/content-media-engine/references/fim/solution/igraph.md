---
name: igraph
description: High-performance network analysis library with bindings for R, Python, and C
docs: https://igraph.org/
examples: https://igraph.org/python/doc/tutorial/tutorial.html
---

# igraph — fast network analysis (Python / R / C) with plotting

igraph is a high-performance graph library implemented in C with first-class Python and R
bindings. Its strength is analysis — hundreds of algorithms (centrality, community
detection, paths, flows, motifs) that run fast on large graphs — plus a capable static
plotting layer (Cairo/matplotlib in Python, base graphics in R). For LLM-authoring, emit
Python `igraph` (imported as `ig`) unless the context is R. It draws to PNG/SVG/PDF, not
to an interactive browser canvas.

**Current Version**: python-igraph 0.11.x / R igraph 2.x (current majors)  **License**: GPL-2  **Runtime**: native C core; scales to millions of edges; plotting is static

## Official Resources & Documentation
- Site: https://igraph.org/
- Python tutorial: https://python.igraph.org/en/stable/tutorial.html
- Python API: https://python.igraph.org/en/stable/api/
- R docs: https://r.igraph.org/
- PyPI: https://pypi.org/project/igraph/

## Installation & Setup

### Python
```bash
pip install igraph          # core (imports as `igraph`, conventionally `ig`)
pip install pycairo         # required for ig.plot() to PNG/SVG/PDF
# matplotlib backend alternative: pip install matplotlib
```

### R
```r
install.packages("igraph")
```

### C
```bash
# Debian/Ubuntu
apt-get install libigraph-dev
```

## Core Syntax / API Reference (Python)

### Constructing graphs
```python
import igraph as ig

g = ig.Graph(directed=False)
g.add_vertices(4)                              # vertices 0..3 by index
g.add_edges([(0, 1), (1, 2), (2, 3), (3, 0)])  # edges by vertex index

# from an edge list with names:
g = ig.Graph.TupleList([("A", "B"), ("B", "C"), ("C", "A")], directed=False)
# other constructors: Graph.Famous('Zachary'), Graph.Erdos_Renyi(n=50, p=0.1),
#   Graph.Barabasi(n=100, m=2), Graph.Read_GraphML('g.graphml'), Graph.DataFrame(df)
```

### Vertex / edge attributes
Attributes are stored on the `.vs` (vertex) and `.es` (edge) sequences and accessed like
dict keys — assigning a list sets one value per element:
```python
g.vs["name"]  = ["A", "B", "C", "D"]
g.vs["group"] = ["x", "x", "y", "y"]
g.es["weight"] = [1.0, 2.0, 1.5, 0.5]

g.vs[0]["name"]          # read one vertex attribute
g.vs.find(name="A")      # lookup by attribute
g.vs.select(group_eq="x")  # filter → VertexSeq
```

### Analysis (the core value)
```python
g.degree(); g.betweenness(); g.closeness(); g.pagerank(weights="weight")
g.diameter(); g.average_path_length(); g.transitivity_undirected()
g.get_shortest_paths(0, to=3, weights="weight")
g.eigenvector_centrality()
```

### Community detection
Returns a `VertexClustering` (or a `VertexDendrogram` you `.as_clustering()`):
```python
comms = g.community_multilevel(weights="weight")      # Louvain
# also: community_leiden, community_edge_betweenness().as_clustering(),
#       community_infomap(), community_fastgreedy().as_clustering(),
#       community_label_propagation(), community_walktrap().as_clustering()
print(comms.membership)      # cluster index per vertex
print(comms.modularity)
```

### Plotting
```python
layout = g.layout_fruchterman_reingold()   # returns a Layout of coordinates
ig.plot(
    g, target="network.png",
    layout=layout,
    vertex_label=g.vs["name"],
    vertex_color=["#4f8ef7" if grp == "x" else "#e0607e" for grp in g.vs["group"]],
    vertex_size=[10 + 3 * d for d in g.degree()],
    edge_width=[2 * w for w in g.es["weight"]],
    bbox=(600, 600), margin=40,
)
```
`target` may be `.png`, `.svg`, or `.pdf`; omit it in a Jupyter/Cairo context to display
inline. To use matplotlib instead: `fig, ax = plt.subplots(); ig.plot(g, target=ax, ...)`.

## Layouts
`layout_fruchterman_reingold` (force), `layout_kamada_kawai` (force, small graphs),
`layout_drl` (large graphs), `layout_circle`, `layout_grid`, `layout_star`,
`layout_reingold_tilford` (trees, needs `root=`), `layout_sugiyama` (layered/DAG),
`layout_bipartite`, `layout_auto` (picks one for you). Call as `g.layout_<name>()` or
`g.layout("fr")` with a short code.

## How-To (worked recipes)

### How to color and size vertices & edges
igraph plotting reads visual attributes either from keyword args to `ig.plot` or from
special attribute names on `g.vs`/`g.es` (`color`, `size`, `label`, `shape`;
`width`/`color` for edges). Compute per-element lists and pass them:
```python
palette = {"x": "#4f8ef7", "y": "#e0607e"}
g.vs["color"] = [palette[grp] for grp in g.vs["group"]]     # persisted on the graph
g.vs["size"]  = [10 + 4 * d for d in g.degree()]            # size by degree
g.es["width"] = [0.5 + w for w in g.es["weight"]]           # width by weight
ig.plot(g, "styled.png", vertex_label=g.vs["name"], bbox=(600, 600))
```
Color communities in one line: `ig.plot(comms, "communities.png")` — plotting a
`VertexClustering` auto-colors and hulls each community.

### How to build and plot a scale-free graph
```python
g = ig.Graph.Barabasi(n=200, m=2)
g.vs["size"] = [4 + 2 * (d ** 0.5) for d in g.degree()]
ig.plot(g, "scalefree.png", layout=g.layout_drl(), vertex_color="#4f8ef7",
        edge_color="#dddddd", bbox=(800, 800), margin=30)
```

### How to read/write interchange formats
```python
g = ig.Graph.Read_GraphML("in.graphml")   # also Read_GML, Read_Pajek, Read_Ncol
g.write_gml("out.gml")                     # write_graphml, write_pajek, write_svg
```

### How to do the same in R
```r
library(igraph)
g <- graph_from_data_frame(edges_df, directed = FALSE)
V(g)$color <- ifelse(V(g)$group == "x", "#4f8ef7", "#e0607e")
V(g)$size  <- 5 + degree(g)
cl <- cluster_louvain(g)
plot(g, layout = layout_with_fr(g), vertex.label = V(g)$name, edge.width = E(g)$weight)
```

### How to visualize with matplotlib as the backend
```python
import matplotlib.pyplot as plt
fig, ax = plt.subplots(figsize=(6, 6))
ig.plot(g, target=ax, layout=g.layout_kamada_kawai(),
        vertex_color=g.vs["color"], vertex_size=20, vertex_label=g.vs["name"],
        edge_color="#cccccc")
fig.savefig("mpl_network.png", dpi=150, bbox_inches="tight")
```

## R igraph parity
The R API mirrors the Python one with `.`→`_`/`V()`/`E()` conventions:
```r
library(igraph)
g <- make_graph(edges = c(1,2, 2,3, 3,1), directed = FALSE)   # or graph_from_data_frame(df)
V(g)$name  <- c("A", "B", "C")
V(g)$color <- c("#4f8ef7", "#e0607e", "#2ecc71")
E(g)$weight <- c(1, 2, 1.5)

# analysis
degree(g); betweenness(g); page_rank(g)$vector
cl <- cluster_louvain(g); membership(cl); modularity(cl)

# plotting (vertex.*/edge.* params)
plot(g, layout = layout_with_fr(g),
     vertex.size = 5 + degree(g) * 3, vertex.label = V(g)$name,
     vertex.color = V(g)$color, edge.width = E(g)$weight, edge.color = "#cccccc")

# interchange
write_graph(g, "out.graphml", format = "graphml")
```
Community functions in R: `cluster_louvain`, `cluster_leiden`, `cluster_edge_betweenness`,
`cluster_infomap`, `cluster_walktrap`, `cluster_fast_greedy`, `cluster_label_prop`.

## Do's and Don'ts

### ✅ Do
- Set visual attributes (`vertex_color`, `vertex_size`, `edge_width`) as per-element lists computed from data (degree, community, weight).
- Install `pycairo` before calling `ig.plot` to a file — without a Cairo (or matplotlib) backend, plotting fails.
- Plot a `VertexClustering` directly to get automatic community colors + hulls.
- Reuse a single `Layout` object across multiple plots so node positions stay stable.

### ❌ Don't
- Don't confuse vertex **index** with the `name` attribute — algorithms return index-based results; map back through `g.vs["name"]`.
- Don't expect interactivity — igraph output is a static image. For pan/zoom in the browser, export GraphML and render with `cytoscape_js`/`sigma_js`.
- Don't call `add_edges` with names unless you built the graph so names resolve — edges are added by index; use `TupleList`/`DataFrame` for named construction.
- Don't forget `weights=` on weighted algorithms (pagerank, betweenness, community) — omitting it silently treats the graph as unweighted.

## Styling, Theming & Customization
- **Vertex visuals**: `color`, `size`, `shape` (`circle`, `square`, `triangle-up`, `rectangle`, `hidden`), `label`, `label_size`, `label_color`, `frame_color`, `frame_width`.
- **Edge visuals**: `color`, `width`, `arrow_size`, `arrow_width`, `curved` (for multi/directed), `label`.
- **Palettes**: `ig.drawing.colors` palettes and `ig.RainbowPalette`; map a numeric attribute through a palette for gradient coloring.
- **Backends**: Cairo (default, best quality) or matplotlib (`target=ax`) for integration into a larger figure.

## Advanced Features
- **Motifs & isomorphism**: `motifs_randesu`, `get_subisomorphisms_vf2`.
- **Flows & cuts**: `maxflow`, `mincut`, `gomory_hu_tree`.
- **Random graph models**: Erdős–Rényi, Barabási–Albert, Watts–Strogatz, configuration model, SBM.
- **Bipartite projection**, spanning trees, k-core decomposition (`coreness`), assortativity.

## Performance & Limits
- **C core = fast**: igraph handles millions of edges for analysis where NetworkX would crawl. Construction from bulk edge lists (`Graph.TupleList`, `Graph.DataFrame`, `add_edges` with a list) is far faster than adding edges one at a time.
- **Plotting, not scale**: `ig.plot` is static and gets cluttered past a few thousand visible nodes — sample/filter, or export GraphML to a web renderer. Rendering cost is dominated by node/label count.
- **Layouts**: `layout_drl` and `layout_fruchterman_reingold` scale to large graphs; `layout_kamada_kawai` is O(n²)-ish, small graphs only.
- **Attribute access** on `.vs`/`.es` returns lists sized to the sequence — vectorized assignment (`g.vs["size"] = [...]`) is the fast path; per-element loops are slower.

## Integration Notes
- **Jupyter/Cairo**: with `pycairo` installed, `ig.plot(g)` displays inline; `ig.plot(g, target=ax)` embeds into a matplotlib figure for composition with other panels.
- **pandas**: `Graph.DataFrame(edges_df, vertices=vertices_df)` builds directly from DataFrames; `g.get_edge_dataframe()` / `g.get_vertex_dataframe()` round-trip back.
- **Interchange**: `Read_GraphML`/`write_graphml`, `Read_GML`, `Read_Pajek`, `Read_Ncol` move graphs to/from Gephi, NetworkX, Cytoscape. `write_svg` emits a standalone SVG.
- **NetworkX bridge**: convert via edge lists / GraphML when you need a NetworkX-only algorithm but igraph's speed for the heavy lifting.

## Common Pitfalls & Troubleshooting
- **`ig.plot` raises about Cairo**: install `pycairo`, or pass a matplotlib `Axes` as `target`.
- **Wrong node labeled**: results are index-ordered; join with `g.vs["name"]`.
- **Community result is a dendrogram**: call `.as_clustering()` (e.g. `community_edge_betweenness().as_clustering()`).
- **`python-igraph` vs `igraph` on PyPI**: modern installs use `pip install igraph`; the old `python-igraph` name still redirects, both import as `igraph`.

## Best For / Avoid For
`network-analysis`, `community-detection`, `centrality`, `bioinformatics`, `large-graphs`, `reproducible-figures` — choose igraph when analysis speed and algorithm breadth matter and static output is fine.
Avoid for: interactive/web visualization (use `sigma_js`/`cytoscape_js`), rich custom styling of a diagram (use a JS lib), or when you're already all-in on the Python `networkx` ecosystem for a small graph.

## See Also
- `networkx.md` — pure-Python analysis, friendlier API, slower on large graphs.
- `gephi.md` — interactive desktop exploration; reads GraphML/GML igraph writes.
- `sigma_js.md` / `cytoscape_js.md` — render igraph exports interactively in the browser.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
