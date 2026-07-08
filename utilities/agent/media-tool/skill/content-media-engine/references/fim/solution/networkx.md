---
name: NetworkX
description: Python library for creation, manipulation, and analysis of complex networks
docs: https://networkx.org/documentation/stable/
examples: https://networkx.org/documentation/stable/auto_examples/index.html
---

# NetworkX — pure-Python graph model, algorithms, and matplotlib drawing

NetworkX is the standard Python library for building, analyzing, and (via matplotlib)
drawing graphs. It is pure Python: extremely flexible and easy to author, with the
broadest algorithm collection in the ecosystem, at the cost of speed on very large graphs
(for millions of edges, prefer `igraph`). Its four graph classes cover undirected,
directed, and multi-edge cases. Drawing is a thin matplotlib layer — good for static
figures, not interactive rendering. For LLM-authoring, emit `networkx as nx` +
`matplotlib.pyplot as plt`.

**Current Version**: networkx 3.x (current major)  **License**: BSD-3  **Runtime**: pure Python; drawing via matplotlib (static PNG/SVG/PDF)

## Official Resources & Documentation
- Docs: https://networkx.org/documentation/stable/
- Tutorial: https://networkx.org/documentation/stable/tutorial.html
- Drawing reference: https://networkx.org/documentation/stable/reference/drawing.html
- Gallery: https://networkx.org/documentation/stable/auto_examples/index.html
- PyPI: https://pypi.org/project/networkx/

## Installation & Setup
```bash
pip install networkx matplotlib
# optional layout/IO backends:
pip install pygraphviz    # graphviz layouts (dot/neato) — needs system graphviz
pip install pydot         # alternative graphviz interface
pip install scipy         # required by some algorithms + spectral/kamada layouts
```

## Core Syntax / API Reference

### Graph classes
```python
import networkx as nx
G  = nx.Graph()          # undirected, single edge between a pair
DG = nx.DiGraph()        # directed
MG = nx.MultiGraph()     # parallel edges allowed
MDG = nx.MultiDiGraph()  # directed + parallel edges
```
Choose the class up front — algorithms behave differently (e.g. `in_degree` only exists
on directed graphs).

### Adding nodes and edges (with attributes)
```python
G.add_node(1, color="red", size=300)
G.add_nodes_from([2, 3, 4])
G.add_nodes_from([(5, {"group": "b"})])          # node + attr dict
G.add_edge(1, 2, weight=4.2, label="calls")
G.add_edges_from([(1, 3), (2, 4)], relation="ref")  # shared attrs
G.add_weighted_edges_from([(3, 4, 1.5), (4, 5, 0.8)])
```
Attributes live in dicts: `G.nodes[1]["color"]`, `G.edges[1, 2]["weight"]`. Iterate with
`G.nodes(data=True)` / `G.edges(data=True)`.

### Inspection
```python
G.number_of_nodes(); G.number_of_edges()
list(G.neighbors(1)); G.degree[1]; G.degree(weight="weight")
nx.density(G); nx.is_connected(G)
```

### Algorithms (a broad sampling)
```python
nx.shortest_path(G, 1, 5, weight="weight")
nx.shortest_path_length(G, 1, 5)
nx.connected_components(G)                       # → generator of node sets
nx.degree_centrality(G); nx.betweenness_centrality(G); nx.closeness_centrality(G)
nx.eigenvector_centrality(G, max_iter=500); nx.pagerank(G, weight="weight")
nx.clustering(G); nx.average_clustering(G)
nx.community.greedy_modularity_communities(G)    # community detection
nx.community.louvain_communities(G, weight="weight")
nx.minimum_spanning_tree(G)
```

### Drawing (matplotlib)
```python
import matplotlib.pyplot as plt
pos = nx.spring_layout(G, seed=42)               # compute node positions first
nx.draw(G, pos, with_labels=True, node_color="#4f8ef7", node_size=500,
        edge_color="#cccccc", font_size=10)
plt.savefig("graph.png", dpi=150, bbox_inches="tight")
```
`nx.draw` is a convenience wrapper; for control use the layered API
`draw_networkx_nodes`, `draw_networkx_edges`, `draw_networkx_labels`,
`draw_networkx_edge_labels` — each takes the same `pos` dict.

## Layouts
`spring_layout` (Fruchterman-Reingold force, the default choice), `kamada_kawai_layout`
(force, nicer on small graphs), `circular_layout`, `shell_layout` (concentric),
`spectral_layout`, `spiral_layout`, `random_layout`, `planar_layout` (planar graphs only),
`bipartite_layout`, `multipartite_layout` (layered by a node attribute), and
`nx.nx_agraph.graphviz_layout(G, prog="dot")` for hierarchical trees via graphviz.
A layout returns a `{node: (x, y)}` dict you pass to every draw call.

## How-To (worked recipes)

### How to color and size nodes & edges
Pass a **list** of colors/sizes ordered to match `G.nodes()` (or `G.edges()`). For a
numeric attribute, pass values plus a colormap and let matplotlib map them.
```python
pos = nx.spring_layout(G, seed=1)

# categorical node color from an attribute:
group_color = {"a": "#4f8ef7", "b": "#e0607e"}
node_colors = [group_color.get(G.nodes[n].get("group"), "#999") for n in G.nodes()]

# node size by degree, edge width by weight:
node_sizes = [100 + 40 * G.degree[n] for n in G.nodes()]
edge_widths = [G.edges[e].get("weight", 1) for e in G.edges()]

nx.draw_networkx_nodes(G, pos, node_color=node_colors, node_size=node_sizes)
nx.draw_networkx_edges(G, pos, width=edge_widths, edge_color="#bbbbbb")
nx.draw_networkx_labels(G, pos, font_size=9)
plt.axis("off")

# numeric → colormap (gradient):
pr = nx.pagerank(G)
nx.draw(G, pos, node_color=[pr[n] for n in G.nodes()], cmap=plt.cm.viridis, node_size=400)
```
Ordering matters: color/size lists are consumed in `G.nodes()` iteration order, so build
them by iterating `G.nodes()` — never hand-index.

### How to visualize communities
```python
comms = nx.community.louvain_communities(G, seed=7)
cmap = plt.cm.tab10
color_of = {}
for i, community in enumerate(comms):
    for n in community:
        color_of[n] = cmap(i % 10)
nx.draw(G, nx.spring_layout(G, seed=7),
        node_color=[color_of[n] for n in G.nodes()], with_labels=True)
```

### How to draw a hierarchy / tree
```python
pos = nx.nx_agraph.graphviz_layout(G, prog="dot")   # needs pygraphviz + system graphviz
nx.draw(G, pos, with_labels=True, arrows=True, node_color="#eef")
```

### How to export to an interchange format
```python
nx.write_graphml(G, "graph.graphml")   # also write_gexf, write_gml, node_link_data (JSON)
data = nx.node_link_data(G)            # JSON dict for D3 / web renderers
H = nx.read_graphml("graph.graphml")
```

### How to draw a directed graph with edge labels and curves
```python
DG = nx.DiGraph()
DG.add_edges_from([("A", "B", {"w": 3}), ("B", "C", {"w": 1}), ("C", "A", {"w": 2})])
pos = nx.circular_layout(DG)
nx.draw_networkx_nodes(DG, pos, node_color="#4f8ef7", node_size=800)
nx.draw_networkx_labels(DG, pos, font_color="white")
nx.draw_networkx_edges(DG, pos, arrows=True, arrowstyle="-|>", arrowsize=18,
                       connectionstyle="arc3,rad=0.15")   # curved to separate A→B / B→A
nx.draw_networkx_edge_labels(DG, pos, edge_labels=nx.get_edge_attributes(DG, "w"))
plt.axis("off")
```

### How to add a colorbar for a centrality metric
```python
pr = nx.pagerank(DG)
nodes = nx.draw_networkx_nodes(DG, pos, node_color=list(pr.values()),
                               cmap=plt.cm.plasma, node_size=700)
nx.draw_networkx_edges(DG, pos, alpha=0.4)
plt.colorbar(nodes, label="PageRank")   # nodes is a PathCollection with the cmap mapping
```

## Graph Generators (quick test data)
`nx.karate_club_graph()`, `nx.les_miserables_graph()`, `nx.complete_graph(n)`,
`nx.cycle_graph(n)`, `nx.path_graph(n)`, `nx.star_graph(n)`, `nx.grid_2d_graph(r, c)`,
`nx.erdos_renyi_graph(n, p, seed=)`, `nx.barabasi_albert_graph(n, m)` (scale-free),
`nx.watts_strogatz_graph(n, k, p)` (small-world), `nx.random_geometric_graph(n, radius)`.
These are the fastest way to get a graph to style/test a pipeline against.

## Do's and Don'ts

### ✅ Do
- Compute `pos` once and reuse it across `draw_networkx_*` calls so nodes, edges, and labels align.
- Build color/size lists by iterating `G.nodes()`/`G.edges()` so ordering matches the draw call.
- Pick the right graph class up front (`DiGraph` for directed metrics like `in_degree`, PageRank direction).
- Export to GEXF/GraphML/`node_link_data` and hand off to a JS renderer when you need interactivity.

### ❌ Don't
- Don't rely on NetworkX for million-edge graphs — it's pure Python; use `igraph` for heavy analysis.
- Don't pass a single color where a per-node list is expected and then wonder why the colormap doesn't apply — `cmap` needs numeric `node_color` values.
- Don't use `spring_layout` without a `seed=` if you need reproducible figures — it's randomized.
- Don't expect `nx.draw` to be interactive — it's a static matplotlib image.

## Styling, Theming & Customization
- **Node styling args**: `node_color`, `node_size`, `node_shape` (matplotlib markers: `o`, `s`, `^`, `d`, `v`), `alpha`, `edgecolors`, `linewidths`, `cmap`, `vmin`/`vmax`.
- **Edge styling args**: `edge_color`, `width`, `style` (`solid`/`dashed`/`dotted`), `alpha`, `arrows`, `arrowstyle`, `arrowsize`, `connectionstyle` (e.g. `'arc3,rad=0.1'` for curves).
- **Labels**: `draw_networkx_labels(font_size, font_color, font_family)`; `draw_networkx_edge_labels(edge_labels=nx.get_edge_attributes(G,'weight'))`.
- **Theming**: it's matplotlib — use `plt.style.use('dark_background')` or a stylesheet; colors come from any matplotlib colormap.

## Advanced Features
- **Generators**: `nx.karate_club_graph()`, `erdos_renyi_graph`, `barabasi_albert_graph`, `watts_strogatz_graph`, `grid_2d_graph`.
- **Flow/matching**: `maximum_flow`, `minimum_cut`, `max_weight_matching`.
- **Isomorphism**: `is_isomorphic`, `GraphMatcher`.
- **Bipartite** submodule; **DAG** utilities (`topological_sort`, `dag_longest_path`).
- **Backends**: NetworkX 3 can dispatch some algorithms to accelerated backends (e.g. `nx-cugraph`) without changing calling code.

## Performance & Limits
- **Pure Python**: fine to low tens of thousands of nodes for analysis; heavy algorithms (all-pairs paths, betweenness) on large graphs are slow — switch to `igraph` or a NetworkX backend.
- **Drawing limit**: matplotlib drawing gets unreadable and slow past ~500–1000 visible nodes. There's no built-in decluttering — filter, sample, or hand off to Gephi/sigma.js.
- **Backends (NetworkX 3)**: some algorithms dispatch to accelerated backends (`nx-cugraph` on GPU, `graphblas`) via the `backend=` kwarg or config, with no code change to the graph model.
- **scipy speedups**: `*_numpy`/`*_scipy` variants (e.g. `eigenvector_centrality_numpy`, `pagerank_scipy` where available) are much faster and more robust than the pure-Python versions.

## Integration Notes
- **pandas**: `nx.from_pandas_edgelist(df, 'src', 'dst', edge_attr=True)` and `nx.to_pandas_edgelist(G)` bridge tabular data.
- **Web handoff (D3/sigma.js/Cytoscape)**: `nx.node_link_data(G)` produces the `{nodes, links}` JSON D3 and Cytoscape.js expect; `nx.write_gexf`/`write_graphml` feed Gephi and sigma.js (via graphology).
- **igraph bridge**: convert through GraphML or edge lists when you want igraph's speed for one step but NetworkX's API elsewhere.
- **Jupyter**: `nx.draw` renders inline; combine with `matplotlib` subplots to place a graph beside other charts.

## Common Pitfalls & Troubleshooting
- **`graphviz_layout` ImportError**: install `pygraphviz` (and the system graphviz `dot`), or fall back to `pydot`.
- **`eigenvector_centrality` fails to converge**: raise `max_iter`, or use `eigenvector_centrality_numpy` (needs scipy).
- **Directed metric on a `Graph`**: `in_degree`/`out_degree` need a `DiGraph`; convert with `G.to_directed()`.
- **Colormap ignored**: `node_color` must be numeric values (not hex strings) for `cmap` to apply.
- **Overlapping labels on big graphs**: NetworkX drawing doesn't declutter — sample, filter, or export to Gephi/sigma.js for large graphs.

## Best For / Avoid For
`network-analysis`, `graph-algorithms`, `scientific-research`, `data-science`, `prototyping`, `small-medium-graphs`, `graph-interchange` — choose NetworkX for flexible analysis and quick static figures in Python.
Avoid for: very large graphs / performance-critical analysis (use `igraph`), interactive web visualization (use `sigma_js`/`cytoscape_js`), or heavily styled diagrams (use a JS diagramming lib).

## See Also
- `igraph.md` — faster C-backed analysis with a similar scope.
- `gephi.md` — interactive exploration; reads NetworkX's GEXF/GraphML exports.
- `cytoscape_js.md` / `sigma_js.md` — render NetworkX `node_link_data`/GraphML in the browser.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
