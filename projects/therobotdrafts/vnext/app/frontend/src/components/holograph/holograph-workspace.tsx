"use client";

import { useEffect, useMemo, useState } from "react";
import { demoDocument, demoPatches } from "@/lib/holograph/fixture";
import { packDocument } from "@/lib/holograph/layout";
import type { GraphDocument, PatchOperation, SceneNode } from "@/lib/holograph/types";

const kindLabels: Record<SceneNode["kind"], string> = {
  system: "SYS",
  package: "PKG",
  service: "SVC",
  class: "CLS",
  interface: "API",
  function: "FN",
  database: "DB",
  agent: "AI",
};

const roadmap = [
  { id: "M0", label: "Foundation", status: "complete" },
  { id: "M1", label: "Load and View", status: "in progress" },
  { id: "M2", label: "Navigate/Search", status: "stubbed" },
  { id: "M3", label: "Authoring/A11y", status: "next" },
  { id: "M4", label: "Ingestion", status: "next" },
  { id: "M5", label: "Interchange", status: "next" },
];

function scoreLabel(value: number) {
  if (value >= 60) return "high";
  if (value >= 35) return "medium";
  return "low";
}

function nodeTone(node: SceneNode) {
  if (node.kind === "system") return "node-system";
  if (node.kind === "agent") return "node-agent";
  if (node.kind === "database") return "node-store";
  if (node.status === "hot") return "node-hot";
  if (node.status === "review") return "node-review";
  return "node-default";
}

function nextNode(nodes: SceneNode[], currentId: string, direction: 1 | -1) {
  const index = nodes.findIndex((node) => node.id === currentId);
  const nextIndex = index < 0 ? 0 : (index + direction + nodes.length) % nodes.length;
  return nodes[nextIndex]?.id ?? currentId;
}

export function HoloGraphWorkspace() {
  const [document, setDocument] = useState<GraphDocument>(demoDocument);
  const [selectedId, setSelectedId] = useState("renderer");
  const [focusId, setFocusId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [traceEnabled, setTraceEnabled] = useState(true);
  const [patches, setPatches] = useState<PatchOperation[]>(demoPatches);
  const [status, setStatus] = useState("Fixture graph loaded from local route handlers");

  useEffect(() => {
    let active = true;
    fetch("/api/v1/docs/trd-demo")
      .then((response) => response.json())
      .then((payload: { data?: GraphDocument }) => {
        if (!active || !payload.data) return;
        setDocument(payload.data);
        setStatus("Loaded /api/v1/docs/trd-demo");
      })
      .catch(() => {
        setStatus("Using bundled fixture while API route initializes");
      });

    return () => {
      active = false;
    };
  }, []);

  const scene = useMemo(() => packDocument(document, focusId), [document, focusId]);
  const selectedNode = scene.nodes.find((node) => node.id === selectedId) ?? scene.nodes[0];
  const normalizedQuery = query.trim().toLowerCase();
  const matchingIds = new Set(
    normalizedQuery
      ? document.nodes
          .filter((node) => {
            const haystack = `${node.label} ${node.kind} ${node.packageName ?? ""} ${node.description}`.toLowerCase();
            return haystack.includes(normalizedQuery);
          })
          .map((node) => node.id)
      : [],
  );
  const visibleMatchingIds = new Set(scene.nodes.filter((node) => matchingIds.has(node.id)).map((node) => node.id));

  const tracedIds = new Set<string>();
  if (traceEnabled && selectedNode) {
    tracedIds.add(selectedNode.id);
    for (const edge of document.edges) {
      if (edge.sourceId === selectedNode.id) tracedIds.add(edge.targetId);
      if (edge.targetId === selectedNode.id) tracedIds.add(edge.sourceId);
    }
  }

  function focusSelected() {
    if (!selectedNode) return;
    setFocusId(selectedNode.id);
    setStatus(`Focused ${selectedNode.label}`);
  }

  function recenter() {
    setFocusId(null);
    setSelectedId("renderer");
    setStatus("Recentered to whole-system overview");
  }

  function drillOut() {
    if (!focusId) return;
    const focused = document.nodes.find((node) => node.id === focusId);
    setFocusId(focused?.parentId ?? null);
    setStatus("Drilled out one containment level");
  }

  function importFixture() {
    setDocument({ ...demoDocument, version: document.version + 1, updatedAt: new Date().toISOString() });
    setFocusId(null);
    setSelectedId("root");
    setStatus("Imported demo .trd-yaml fixture as a new document version");
  }

  function applyPatch() {
    const nextPatch = patches.find((patch) => patch.status !== "applied");
    if (!nextPatch) {
      setStatus("No pending patches in the review queue");
      return;
    }

    setPatches((current) =>
      current.map((patch) => (patch.id === nextPatch.id ? { ...patch, status: "applied" } : patch)),
    );
    setStatus(`Applied patch ${nextPatch.id}: ${nextPatch.label}`);
  }

  function handleKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    if (!scene.nodes.length) return;
    if (event.key === "f" || event.key === "F") {
      event.preventDefault();
      focusSelected();
    }
    if (event.key === "Home") {
      event.preventDefault();
      recenter();
    }
    if (event.key === "ArrowRight") {
      event.preventDefault();
      setSelectedId(nextNode(scene.nodes, selectedId, 1));
    }
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      setSelectedId(nextNode(scene.nodes, selectedId, -1));
    }
    if (event.key === "Escape") {
      event.preventDefault();
      drillOut();
    }
  }

  return (
    <main className="hg-shell" onKeyDown={handleKeyDown} tabIndex={-1}>
      <section className="hg-topbar" aria-label="Workspace status">
        <div>
          <p className="hg-kicker">The Robot Drafts vnext</p>
          <h1>HoloGraph workspace</h1>
        </div>
        <div className="hg-topbar__stats" aria-label="Document metrics">
          <span>v{document.version}</span>
          <span>{document.nodes.length} nodes</span>
          <span>{document.edges.length} edges</span>
          <span>{status}</span>
        </div>
      </section>

      <section className="hg-workspace" aria-label="Graph document workspace">
        <aside className="hg-panel hg-panel--left" aria-label="Project controls">
          <div className="hg-panel__section">
            <label className="hg-label" htmlFor="graph-search">
              Search graph
            </label>
            <input
              id="graph-search"
              className="hg-input"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="service, patch, renderer"
            />
            <p className="hg-help">{matchingIds.size || scene.nodes.length} matching nodes</p>
          </div>

          <div className="hg-panel__section">
            <p className="hg-label">Command rail</p>
            <button className="hg-command hg-command--primary" type="button" onClick={importFixture}>
              Import fixture
            </button>
            <button className="hg-command" type="button" onClick={focusSelected}>
              Focus selected
            </button>
            <button className="hg-command" type="button" onClick={recenter}>
              Recenter
            </button>
            <button className="hg-command" type="button" onClick={drillOut} disabled={!focusId}>
              Drill out
            </button>
            <label className="hg-toggle">
              <input
                type="checkbox"
                checked={traceEnabled}
                onChange={(event) => setTraceEnabled(event.target.checked)}
              />
              Trace neighbors
            </label>
          </div>

          <div className="hg-panel__section">
            <p className="hg-label">Roadmap progress</p>
            <ol className="hg-roadmap">
              {roadmap.map((item) => (
                <li key={item.id}>
                  <span>{item.id}</span>
                  <strong>{item.label}</strong>
                  <em>{item.status}</em>
                </li>
              ))}
            </ol>
          </div>
        </aside>

        <section className="hg-canvas-wrap" aria-label="Interactive graph renderer">
          <div className="hg-canvas-toolbar">
            <div>
              <strong>{focusId ? `Focused: ${document.nodes.find((node) => node.id === focusId)?.label}` : "Whole system"}</strong>
              <span>Arrow keys select; F focuses; Home recenters; Esc drills out.</span>
            </div>
            <div className="hg-mode-chip">M1 renderer payload</div>
          </div>
          <svg className="hg-canvas" viewBox="0 0 100 100" role="img" aria-label="3D graph renderer stand-in">
            <defs>
              <radialGradient id="nodeGlow" cx="36%" cy="28%" r="70%">
                <stop offset="0%" stopColor="#ffffff" stopOpacity="0.98" />
                <stop offset="48%" stopColor="#8ed7d1" stopOpacity="0.88" />
                <stop offset="100%" stopColor="#2a756d" stopOpacity="0.95" />
              </radialGradient>
              <radialGradient id="nodeHot" cx="36%" cy="28%" r="70%">
                <stop offset="0%" stopColor="#fff7d6" stopOpacity="0.98" />
                <stop offset="52%" stopColor="#f2bd52" stopOpacity="0.92" />
                <stop offset="100%" stopColor="#8b4a11" stopOpacity="0.95" />
              </radialGradient>
            </defs>
            {scene.edges.map((edge) => {
              const isTrace = tracedIds.has(edge.sourceId) && tracedIds.has(edge.targetId);
              return (
                <g key={edge.id} className={isTrace ? "hg-edge hg-edge--trace" : "hg-edge"}>
                  <line x1={edge.source.x} y1={edge.source.y} x2={edge.target.x} y2={edge.target.y} />
                  <text x={(edge.source.x + edge.target.x) / 2} y={(edge.source.y + edge.target.y) / 2}>
                    {edge.label}
                  </text>
                </g>
              );
            })}
            {scene.nodes.map((node) => {
              const selected = node.id === selectedNode?.id;
              const matched = visibleMatchingIds.has(node.id);
              const traced = tracedIds.has(node.id);
              return (
                <g
                  key={node.id}
                  className={[
                    "hg-node",
                    nodeTone(node),
                    selected ? "is-selected" : "",
                    matched ? "is-matched" : "",
                    traced ? "is-traced" : "",
                  ].join(" ")}
                  transform={`translate(${node.x} ${node.y})`}
                  onClick={() => setSelectedId(node.id)}
                  tabIndex={0}
                  role="button"
                  aria-label={`Select ${node.label}`}
                >
                  <circle r={node.radius} />
                  <text className="hg-node__kind" y={-2}>
                    {kindLabels[node.kind]}
                  </text>
                  <text className="hg-node__label" y={3.8}>
                    {node.label}
                  </text>
                  <text className="hg-node__meta" y={7.8}>
                    risk {node.metrics.risk}
                  </text>
                </g>
              );
            })}
          </svg>
        </section>

        <aside className="hg-panel hg-panel--right" aria-label="Selection detail panel">
          {selectedNode ? (
            <>
              <div className="hg-detail-heading">
                <span className={`hg-kind-dot ${nodeTone(selectedNode)}`} aria-hidden="true" />
                <div>
                  <p className="hg-kicker">{selectedNode.kind}</p>
                  <h2>{selectedNode.label}</h2>
                </div>
              </div>
              <p className="hg-description">{selectedNode.description}</p>
              <dl className="hg-metrics">
                <div>
                  <dt>Complexity</dt>
                  <dd>{selectedNode.metrics.complexity} - {scoreLabel(selectedNode.metrics.complexity)}</dd>
                </div>
                <div>
                  <dt>Churn</dt>
                  <dd>{selectedNode.metrics.churn} - {scoreLabel(selectedNode.metrics.churn)}</dd>
                </div>
                <div>
                  <dt>Risk</dt>
                  <dd>{selectedNode.metrics.risk} - {scoreLabel(selectedNode.metrics.risk)}</dd>
                </div>
              </dl>
              <div className="hg-panel__section">
                <p className="hg-label">Members</p>
                <ul className="hg-members">
                  {(selectedNode.members ?? ["No members recorded"]).map((member) => (
                    <li key={member}>{member}</li>
                  ))}
                </ul>
              </div>
              <div className="hg-panel__section">
                <p className="hg-label">Patch queue</p>
                <ul className="hg-patches">
                  {patches.map((patch) => (
                    <li key={patch.id} className={`patch-${patch.status}`}>
                      <span>{patch.id}</span>
                      <strong>{patch.label}</strong>
                      <em>{patch.status}</em>
                    </li>
                  ))}
                </ul>
                <button className="hg-command hg-command--primary" type="button" onClick={applyPatch}>
                  Apply next patch
                </button>
              </div>
            </>
          ) : null}
        </aside>
      </section>
    </main>
  );
}
