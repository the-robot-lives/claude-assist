# igraph

## What
igraph is a high-performance network analysis library with bindings for R, Python, and C. It builds and analyzes graphs (diameter, betweenness, PageRank, community detection) and produces static plots. Primary consumer is a scripting/analysis runtime (Python, R, or C/C++).

## How
- The LLM emits (typically) Python that constructs a graph with `ig.Graph()`, adds vertices/edges and attributes, runs analysis methods (`g.diameter()`, `g.betweenness()`, `g.pagerank()`, `community_edge_betweenness()`), computes a layout (`layout_fruchterman_reingold()`), and renders via `ig.plot()`.
- Turned into a viewable artifact by installing the language binding (`pip install python-igraph cairocffi`, R `install.packages("igraph")`, or `libigraph-dev`); `ig.plot()` renders through Cairo to an image/`bbox`.
- Typical final artifact: a static plotted image (Cairo output) or numeric analysis results.

## Why
- Reach for igraph when performance and algorithm breadth on large graphs matter: large-scale network analysis, bioinformatics, social network analysis, and graph algorithms. Strengths are excellent performance, a rich algorithm collection, multi-language support, and memory efficiency.
- Limitations: basic visualization, a steeper learning curve, and limited interactive features.
- Versus [[networkx]] — both are scripting analysis libraries, but igraph is C-backed and faster/more memory-efficient at scale, where NetworkX is pure-Python and more approachable.

## Source
- Solution reference: `fim/solution/igraph.md`
