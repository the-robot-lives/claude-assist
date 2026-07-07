"use client";

import { useEffect, useRef } from "react";
import cytoscape, { type Core, type StylesheetStyle } from "cytoscape";
import type { MemoryNode, MemoryEdge } from "@/lib/api";
import {
  contentTypeColor,
  edgeTypeColor,
  salienceToSize,
  weightToWidth,
} from "@/lib/memory-viz";

interface GraphCanvasProps {
  nodes: MemoryNode[];
  edges: MemoryEdge[];
  selectedId: string | null;
  onSelectNode: (id: string) => void;
  onSelectEdge: (id: string) => void;
  onBackground: () => void;
}

interface Theme {
  text: string;
  selection: string;
  pin: string;
}

function readTheme(el: HTMLElement): Theme {
  const cs = getComputedStyle(el);
  const v = (name: string, fb: string) => cs.getPropertyValue(name).trim() || fb;
  return {
    text: v("--text", "#111827"),
    selection: v("--brand-blue", "#0047ab"),
    pin: v("--warning", "#d97706"),
  };
}

function truncate(s: string, n: number): string {
  if (!s) return "";
  return s.length > n ? `${s.slice(0, n - 1)}…` : s;
}

function nodeData(n: MemoryNode) {
  return {
    id: n.id,
    label: truncate(n.summary || n.content_type || n.id, 26),
    color: contentTypeColor(n.content_type),
    size: salienceToSize(n.salience),
  };
}

function edgeData(e: MemoryEdge) {
  return {
    id: e.id,
    source: e.source,
    target: e.target,
    color: edgeTypeColor(e.type),
    width: weightToWidth(e.weight),
  };
}

function buildStylesheet(theme: Theme): StylesheetStyle[] {
  return [
    {
      selector: "node",
      style: {
        "background-color": "data(color)",
        width: "data(size)",
        height: "data(size)",
        label: "data(label)",
        "font-size": 9,
        color: theme.text,
        "text-valign": "bottom",
        "text-halign": "center",
        "text-margin-y": 3,
        "text-wrap": "ellipsis",
        "text-max-width": "100px",
        "border-width": 0,
      },
    },
    {
      selector: "node.pinned",
      style: {
        "border-width": 3,
        "border-color": theme.pin,
        "border-style": "double",
      },
    },
    {
      selector: "node.selected",
      style: { "border-width": 4, "border-color": theme.selection },
    },
    {
      selector: "edge",
      style: {
        "line-color": "data(color)",
        width: "data(width)",
        "curve-style": "bezier",
        opacity: 0.7,
      },
    },
    {
      selector: "edge.selected",
      style: { "line-color": theme.selection, opacity: 1 },
    },
  ] as unknown as StylesheetStyle[];
}

export default function GraphCanvas({
  nodes,
  edges,
  selectedId,
  onSelectNode,
  onSelectEdge,
  onBackground,
}: GraphCanvasProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const cyRef = useRef<Core | null>(null);
  const nodeSigRef = useRef<string>("");
  const edgeSigRef = useRef<string>("");

  // Keep event callbacks fresh without re-initializing cytoscape.
  const handlersRef = useRef({ onSelectNode, onSelectEdge, onBackground });
  handlersRef.current = { onSelectNode, onSelectEdge, onBackground };

  // Init once.
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    const theme = readTheme(container);
    const cy = cytoscape({
      container,
      elements: [],
      style: buildStylesheet(theme),
      minZoom: 0.15,
      maxZoom: 3,
      wheelSensitivity: 0.2,
    });
    cyRef.current = cy;

    cy.on("tap", "node", (evt) => handlersRef.current.onSelectNode(evt.target.id()));
    cy.on("tap", "edge", (evt) => handlersRef.current.onSelectEdge(evt.target.id()));
    cy.on("tap", (evt) => {
      if (evt.target === cy) handlersRef.current.onBackground();
    });

    // Re-read theme colors when the light/dark class flips.
    const observer = new MutationObserver(() => {
      if (!cyRef.current) return;
      cyRef.current.style(buildStylesheet(readTheme(container)));
    });
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class", "data-theme", "data-design-theme"],
    });

    return () => {
      observer.disconnect();
      cy.destroy();
      cyRef.current = null;
    };
  }, []);

  // Sync elements on data change; only re-layout when topology changes.
  useEffect(() => {
    const cy = cyRef.current;
    if (!cy) return;

    const incomingNodeIds = new Set(nodes.map((n) => n.id));

    cy.batch(() => {
      cy.nodes().forEach((n) => {
        if (!incomingNodeIds.has(n.id())) n.remove();
      });
      nodes.forEach((n) => {
        const existing = cy.getElementById(n.id);
        if (existing.nonempty()) {
          existing.data(nodeData(n));
          existing.toggleClass("pinned", n.pinned);
        } else {
          cy.add({
            group: "nodes",
            data: nodeData(n),
            classes: n.pinned ? "pinned" : "",
          });
        }
      });

      const incomingEdgeIds = new Set(edges.map((e) => e.id));
      cy.edges().forEach((e) => {
        if (!incomingEdgeIds.has(e.id())) e.remove();
      });
      edges.forEach((e) => {
        if (!incomingNodeIds.has(e.source) || !incomingNodeIds.has(e.target)) return;
        const existing = cy.getElementById(e.id);
        if (existing.nonempty()) existing.data(edgeData(e));
        else cy.add({ group: "edges", data: edgeData(e) });
      });
    });

    const nodeSig = nodes.map((n) => n.id).sort().join(",");
    const edgeSig = edges.map((e) => e.id).sort().join(",");
    if (nodeSig !== nodeSigRef.current || edgeSig !== edgeSigRef.current) {
      nodeSigRef.current = nodeSig;
      edgeSigRef.current = edgeSig;
      if (cy.nodes().length > 0) {
        cy.layout({
          name: "cose",
          animate: false,
          padding: 30,
          nodeRepulsion: () => 12000,
          idealEdgeLength: () => 90,
        }).run();
      }
    }
  }, [nodes, edges]);

  // Reflect current selection.
  useEffect(() => {
    const cy = cyRef.current;
    if (!cy) return;
    cy.elements().removeClass("selected");
    if (selectedId) cy.getElementById(selectedId).addClass("selected");
  }, [selectedId]);

  return <div ref={containerRef} className="mem-canvas__inner" />;
}
