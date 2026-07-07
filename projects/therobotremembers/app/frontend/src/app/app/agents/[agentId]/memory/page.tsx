"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { api, type MemoryGraph, type MemoryNode, type MemoryEdge } from "@/lib/api";
import Legend from "./_components/legend";
import NodeList from "./_components/node-list";
import NodePanel from "./_components/node-panel";
import EdgePanel from "./_components/edge-panel";

const GraphCanvas = dynamic(() => import("./_components/graph-canvas"), {
  ssr: false,
  loading: () => <div className="mem-canvas__overlay">Loading graph…</div>,
});

const EMPTY_GRAPH: MemoryGraph = { nodes: [], edges: [], truncated: false };
type Selection = { type: "node" | "edge"; id: string } | null;

function shortLabel(node: MemoryNode | undefined, id: string): string {
  if (node?.summary) return node.summary.length > 30 ? `${node.summary.slice(0, 29)}…` : node.summary;
  return id.slice(0, 8);
}

export default function MemoryGraphPage() {
  const { agentId: rawAgentId } = useParams<{ agentId: string }>();
  const agentId = rawAgentId ?? "";

  const [graph, setGraph] = useState<MemoryGraph>(EMPTY_GRAPH);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [minWeight, setMinWeight] = useState(0.2);
  const [debouncedMinWeight, setDebouncedMinWeight] = useState(0.2);
  const [compartment, setCompartment] = useState<string>("all");
  const [compartmentOptions, setCompartmentOptions] = useState<string[]>([]);
  const [view, setView] = useState<"graph" | "list">("graph");
  const [selection, setSelection] = useState<Selection>(null);

  // Debounce the weight slider before hitting the server.
  useEffect(() => {
    const t = setTimeout(() => setDebouncedMinWeight(minWeight), 350);
    return () => clearTimeout(t);
  }, [minWeight]);

  // Fetch graph when the agent / server-side filters change.
  useEffect(() => {
    if (!agentId) return;
    let active = true;
    setLoading(true);
    setError(null);
    api
      .getMemoryGraph(agentId, {
        min_weight: debouncedMinWeight,
        compartment: compartment === "all" ? undefined : compartment,
        limit: 500,
      })
      .then((res) => {
        if (!active) return;
        setGraph({
          nodes: res.nodes ?? [],
          edges: res.edges ?? [],
          truncated: res.truncated ?? false,
        });
        setCompartmentOptions((prev) => {
          const union = new Set(prev);
          (res.nodes ?? []).forEach((n) => n.compartment && union.add(n.compartment));
          return Array.from(union).sort();
        });
      })
      .catch((e: unknown) => {
        if (!active) return;
        setError(e instanceof Error ? e.message : "Failed to load graph");
        setGraph(EMPTY_GRAPH);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [agentId, debouncedMinWeight, compartment]);

  const selectedNode = useMemo(
    () => (selection?.type === "node" ? graph.nodes.find((n) => n.id === selection.id) ?? null : null),
    [selection, graph.nodes]
  );
  const selectedEdge = useMemo(
    () => (selection?.type === "edge" ? graph.edges.find((e) => e.id === selection.id) ?? null : null),
    [selection, graph.edges]
  );

  const nodeById = useCallback(
    (id: string) => graph.nodes.find((n) => n.id === id),
    [graph.nodes]
  );

  // ─── Mutations (optimistic where a value is known) ───────────────

  const applyEdgeWeight = useCallback(
    async (edge: MemoryEdge, weight: number, reason: string) => {
      const prev = edge;
      setGraph((g) => ({ ...g, edges: g.edges.map((e) => (e.id === edge.id ? { ...e, weight } : e)) }));
      try {
        const updated = await api.updateMemoryEdge(agentId, edge.id, { weight, reason });
        setGraph((g) => ({ ...g, edges: g.edges.map((e) => (e.id === updated.id ? updated : e)) }));
        toast.success("Edge weight updated");
      } catch (e) {
        setGraph((g) => ({ ...g, edges: g.edges.map((edge2) => (edge2.id === prev.id ? prev : edge2)) }));
        toast.error(e instanceof Error ? e.message : "Failed to update edge");
      }
    },
    [agentId]
  );

  const togglePin = useCallback(
    async (node: MemoryNode) => {
      const prev = node;
      const next = { ...node, pinned: !node.pinned };
      setGraph((g) => ({ ...g, nodes: g.nodes.map((n) => (n.id === node.id ? next : n)) }));
      try {
        const updated = await api.updateMemoryNode(agentId, node.id, { pinned: next.pinned });
        setGraph((g) => ({ ...g, nodes: g.nodes.map((n) => (n.id === updated.id ? updated : n)) }));
        toast.success(updated.pinned ? "Memory pinned" : "Memory unpinned");
      } catch (e) {
        setGraph((g) => ({ ...g, nodes: g.nodes.map((n) => (n.id === prev.id ? prev : n)) }));
        toast.error(e instanceof Error ? e.message : "Failed to update memory");
      }
    },
    [agentId]
  );

  const reinforce = useCallback(
    async (node: MemoryNode) => {
      try {
        const updated = await api.reinforceMemory(agentId, node.id);
        setGraph((g) => ({ ...g, nodes: g.nodes.map((n) => (n.id === updated.id ? updated : n)) }));
        toast.success("Memory reinforced");
      } catch (e) {
        toast.error(e instanceof Error ? e.message : "Failed to reinforce");
      }
    },
    [agentId]
  );

  const denforce = useCallback(
    async (node: MemoryNode) => {
      try {
        const updated = await api.denforceMemory(agentId, node.id);
        setGraph((g) => ({ ...g, nodes: g.nodes.map((n) => (n.id === updated.id ? updated : n)) }));
        toast.success("Memory weakened");
      } catch (e) {
        toast.error(e instanceof Error ? e.message : "Failed to denforce");
      }
    },
    [agentId]
  );

  const showPanel = selectedNode !== null || selectedEdge !== null;

  return (
    <div className="mem-page">
      <div className="mem-breadcrumb">
        <Link href="/app/agents">Agents</Link> / {agentId}
      </div>

      <div className="mem-header">
        <div>
          <h1 className="mem-title">Memory graph</h1>
          <p className="mem-subtitle">
            {graph.nodes.length} memories · {graph.edges.length} associations
          </p>
        </div>
        <Link
          href={`/app/agents/${encodeURIComponent(agentId)}/memory/playground`}
          className="sg-btn sg-btn--outline sg-btn--sm"
        >
          Recall playground →
        </Link>
      </div>

      <div className="mem-toolbar">
        <div className="mem-control">
          <span className="mem-control__label">
            Min weight <span className="mem-control__value">{minWeight.toFixed(2)}</span>
          </span>
          <input
            className="mem-slider"
            type="range"
            min={0}
            max={1}
            step={0.05}
            value={minWeight}
            onChange={(e) => setMinWeight(parseFloat(e.target.value))}
          />
        </div>

        <div className="mem-control">
          <span className="mem-control__label">Compartment</span>
          <select value={compartment} onChange={(e) => setCompartment(e.target.value)}>
            <option value="all">All</option>
            {compartmentOptions.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>

        <div className="mem-spacer" />

        <div className="mem-control">
          <span className="mem-control__label">View</span>
          <div className="mem-toggle" role="group" aria-label="View mode">
            <button aria-pressed={view === "graph"} onClick={() => setView("graph")}>
              Graph
            </button>
            <button aria-pressed={view === "list"} onClick={() => setView("list")}>
              List
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="mem-banner mem-banner--error" role="alert">
          {error}
        </div>
      )}
      {graph.truncated && (
        <div className="mem-banner mem-banner--warning">
          Result truncated to the node limit — raise the min-weight threshold to
          narrow the graph.
        </div>
      )}

      {view === "graph" && <Legend nodes={graph.nodes} edges={graph.edges} />}

      <div className={`mem-layout ${showPanel ? "mem-layout--with-panel" : ""}`}>
        <div>
          {view === "graph" ? (
            <div className="mem-canvas">
              {!loading && graph.nodes.length === 0 && (
                <div className="mem-canvas__overlay">
                  {error ? "Could not load graph." : "No memories match the current filters."}
                </div>
              )}
              {loading && <div className="mem-canvas__overlay">Loading graph…</div>}
              <GraphCanvas
                nodes={graph.nodes}
                edges={graph.edges}
                selectedId={selection?.id ?? null}
                onSelectNode={(id) => setSelection({ type: "node", id })}
                onSelectEdge={(id) => setSelection({ type: "edge", id })}
                onBackground={() => setSelection(null)}
              />
            </div>
          ) : loading ? (
            <div className="mem-empty">Loading memories…</div>
          ) : (
            <NodeList
              nodes={graph.nodes}
              selectedId={selection?.type === "node" ? selection.id : null}
              onSelect={(id) => setSelection({ type: "node", id })}
            />
          )}
        </div>

        {selectedNode && (
          <NodePanel
            node={selectedNode}
            onReinforce={() => reinforce(selectedNode)}
            onDenforce={() => denforce(selectedNode)}
            onTogglePin={() => togglePin(selectedNode)}
            onClose={() => setSelection(null)}
          />
        )}
        {selectedEdge && (
          <EdgePanel
            key={selectedEdge.id}
            edge={selectedEdge}
            sourceLabel={shortLabel(nodeById(selectedEdge.source), selectedEdge.source)}
            targetLabel={shortLabel(nodeById(selectedEdge.target), selectedEdge.target)}
            onApply={(weight, reason) => applyEdgeWeight(selectedEdge, weight, reason)}
            onClose={() => setSelection(null)}
          />
        )}
      </div>
    </div>
  );
}
