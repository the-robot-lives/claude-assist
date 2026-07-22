"use client";

import * as React from "react";
import dynamic from "next/dynamic";
import { useParams, useRouter } from "next/navigation";
import { GraphControls } from "@/components/graph/graph-controls";
import { GraphLegend } from "@/components/graph/graph-legend";
import type { GraphNode, GraphEdge } from "@/components/graph/knowledge-graph";
import type { EntryType } from "@/lib/constants";
import { graphApi } from "@/lib/api";
import { Loader2 } from "lucide-react";

const KnowledgeGraph = dynamic(
  () =>
    import("@/components/graph/knowledge-graph").then((m) => m.KnowledgeGraph),
  {
    ssr: false,
    loading: () => (
      <div className="w-full h-full bg-page animate-pulse flex items-center justify-center">
        <p className="font-mono text-[11px] text-ink-tertiary">Loading graph…</p>
      </div>
    ),
  },
);

export default function GraphPage() {
  const params = useParams<{ universeId: string }>();
  const router = useRouter();
  const universeId = params.universeId;

  const [searchQuery, setSearchQuery] = React.useState("");
  const [typeFilter, setTypeFilter] = React.useState<EntryType | "all">("all");
  const [nodes, setNodes] = React.useState<GraphNode[]>([]);
  const [edges, setEdges] = React.useState<GraphEdge[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const data = await graphApi.get(universeId, {
          type: typeFilter === "all" ? undefined : typeFilter,
        });
        if (cancelled) return;
        setNodes(
          data.nodes.map((n) => ({
            id: n.id,
            label: n.label,
            type: n.type,
            status: n.status === "draft" ? "generated" : n.status,
          })),
        );
        setEdges(
          data.edges.map((e) => ({
            source: e.source,
            target: e.target,
            relationship: e.relationship,
          })),
        );
        setError(null);
      } catch (e) {
        if (!cancelled)
          setError(e instanceof Error ? e.message : "Failed to load graph");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [universeId, typeFilter]);

  const filteredNodes = React.useMemo(() => {
    return nodes.filter((n) => {
      return (
        searchQuery === "" ||
        n.label.toLowerCase().includes(searchQuery.toLowerCase())
      );
    });
  }, [nodes, searchQuery]);

  const filteredEdges = React.useMemo(() => {
    const nodeIds = new Set(filteredNodes.map((n) => n.id));
    return edges.filter((e) => nodeIds.has(e.source) && nodeIds.has(e.target));
  }, [filteredNodes, edges]);

  function handleNodeClick(node: GraphNode) {
    router.push(`/${universeId}/entries/${node.id}`);
  }

  return (
    <div className="flex flex-col h-full">
      <GraphControls
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        typeFilter={typeFilter}
        onTypeFilterChange={setTypeFilter}
        onZoomIn={() =>
          window.dispatchEvent(
            new CustomEvent("kb:graph:zoom", { detail: { delta: 0.25 } }),
          )
        }
        onZoomOut={() =>
          window.dispatchEvent(
            new CustomEvent("kb:graph:zoom", { detail: { delta: -0.25 } }),
          )
        }
        onFitToScreen={() => window.dispatchEvent(new CustomEvent("kb:graph:fit"))}
      />

      <div className="flex-1 min-h-0 relative">
        {loading ? (
          <div className="absolute inset-0 flex items-center justify-center gap-2 text-ink-secondary">
            <Loader2 className="animate-spin" size={16} /> Loading graph…
          </div>
        ) : error ? (
          <div className="p-8 text-flag-warn">{error}</div>
        ) : (
          <KnowledgeGraph
            nodes={filteredNodes}
            edges={filteredEdges}
            onNodeClick={handleNodeClick}
          />
        )}
      </div>

      <div className="shrink-0">
        <GraphLegend />
        <div className="px-4 py-2 bg-elevated border-t border-rule">
          <p className="font-mono text-[11px] text-ink-tertiary">
            {filteredNodes.length} nodes · {filteredEdges.length} edges
          </p>
        </div>
      </div>
    </div>
  );
}
