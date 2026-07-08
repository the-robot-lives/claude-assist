# NetworkX

## What
NetworkX is a comprehensive Python library for the creation, manipulation, and analysis of complex networks. It provides graph-theory algorithms (density, shortest path, clustering) plus matplotlib-based visualization. Primary consumer is the Python runtime.

## How
- The LLM emits Python that builds a graph with `nx.Graph()`, adds nodes/edges (`add_nodes_from`, `add_edges_from`), runs analysis (`nx.density`, `nx.shortest_path`, `nx.average_clustering`), computes a layout (`nx.spring_layout`), and draws with `nx.draw(G, pos, …)` before `plt.show()`.
- Turned into a viewable artifact via `pip install networkx matplotlib` (optionally `pygraphviz`/`pydot` for extra layouts); rendering goes through matplotlib.
- Typical final artifact: a static matplotlib figure (on-screen or saved image), or numeric analysis output.

## Why
- Reach for NetworkX when doing network analysis, graph algorithms, scientific research, and data-science workflows in Python. Strengths are its extensive algorithm set, multiple layout options, scientific-computing integration, active development, and great documentation.
- Limitations: Python-only, basic visualization, and not intended for real-time rendering.
- Versus [[igraph]] — NetworkX is pure-Python and easier to pick up; igraph is C-backed and faster on large graphs. For interactive exploration instead of scripted analysis, use [[gephi]].

## Source
- Solution reference: `fim/solution/networkx.md`
