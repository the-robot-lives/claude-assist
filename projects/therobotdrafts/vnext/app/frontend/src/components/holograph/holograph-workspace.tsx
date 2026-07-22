"use client";

import { useEffect, useMemo, useState } from "react";
import { graphMetrics, riskBandFor, searchNodes, traceNeighbors } from "@/lib/holograph/analysis";
import { demoDocument, demoPatches } from "@/lib/holograph/fixture";
import type { GraphDocument, GraphNode, PatchOperation } from "@/lib/holograph/types";
import { CollabStrip } from "./collab-strip";
import { TrdThreeScene } from "./trd-three-scene";

const roadmap = [
  { id: "M0", label: "Foundation", status: "complete" },
  { id: "M1", label: "Load and View", status: "in progress" },
  { id: "M2", label: "Navigate/Search", status: "stubbed" },
  { id: "M3", label: "Authoring/A11y", status: "next" },
  { id: "M4", label: "Ingestion", status: "next" },
  { id: "M5", label: "Interchange", status: "next" },
];

const menuGroups = [
  { label: "File", items: ["New", "Open...", "Save", "Save As...", "Import PlantUML...", "Export Code..."] },
  { label: "Edit", items: ["Undo", "Redo", "Copy", "Paste", "Delete"] },
  { label: "Add", items: ["Class", "Interface", "Package", "Service", "Agent", "Datastore", "Region"] },
  { label: "Generate", items: ["Draft patch", "Generate code", "LLM settings", "Test connection"] },
  { label: "Layout", items: ["Frame All", "Hierarchy", "Cluster", "Reflow layer", "Reset view"] },
  { label: "Export", items: ["PlantUML", "Mermaid", "DOT", "PNG render"] },
  { label: "Settings", items: ["Camera", "Notation", "Accessibility", "Shortcuts"] },
];

const paletteGroups = [
  { label: "UML", items: ["Class", "Interface", "Enum", "Struct", "Operation", "Field", "Note"] },
  { label: "Architecture", items: ["Package", "Component", "Service", "Database", "Boundary", "Actor"] },
  { label: "Round-trip", items: ["Import code", "Generate code", "Patch review"] },
];

function scoreLabel(value: number) {
  return riskBandFor(value);
}

function nodeTone(node: GraphNode) {
  if (node.kind === "system") return "node-system";
  if (node.kind === "agent") return "node-agent";
  if (node.kind === "database") return "node-store";
  if (node.status === "hot") return "node-hot";
  if (node.status === "review") return "node-review";
  return "node-default";
}

function nextNode(nodes: GraphNode[], currentId: string, direction: 1 | -1) {
  const index = nodes.findIndex((node) => node.id === currentId);
  const nextIndex = index < 0 ? 0 : (index + direction + nodes.length) % nodes.length;
  return nodes[nextIndex]?.id ?? currentId;
}

export function HoloGraphWorkspace() {
  const [document, setDocument] = useState<GraphDocument>(demoDocument);
  const [selectedId, setSelectedId] = useState("root");
  const [focusId, setFocusId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [traceEnabled, setTraceEnabled] = useState(true);
  const [patches, setPatches] = useState<PatchOperation[]>(demoPatches);
  const [status, setStatus] = useState("3D UML fixture loaded from local route handlers");

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

  const metrics = useMemo(() => graphMetrics(document), [document]);
  const selectedNode = document.nodes.find((node) => node.id === selectedId) ?? document.nodes[0];
  const matchingNodes = useMemo(() => searchNodes(document, query), [document, query]);
  const matchingIds = new Set(matchingNodes.map((node) => node.id));
  const trace = useMemo(
    () => (selectedNode ? traceNeighbors(document, selectedNode.id) : null),
    [document, selectedNode],
  );
  const tracedEdgeIds = new Set(traceEnabled && trace ? trace.edgeIds : []);

  function focusSelected() {
    if (!selectedNode) return;
    setFocusId(selectedNode.id);
    setStatus(`Focused ${selectedNode.label}`);
  }

  function recenter() {
    setFocusId(null);
    setSelectedId("root");
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
    setStatus("Imported Unity-parity 3D UML fixture as a new document version");
  }

  function applyPatch() {
    const nextPatch = patches.find((patch) => patch.status !== "applied");
    if (!nextPatch) {
      setStatus("No pending patches in the review queue");
      return;
    }

    fetch(`/api/v1/docs/${document.id}/patches`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ patchId: nextPatch.id, operation: nextPatch }),
    }).catch(() => {
      setStatus("Patch applied locally; API acknowledgement was unavailable");
    });

    setPatches((current) =>
      current.map((patch) => (patch.id === nextPatch.id ? { ...patch, status: "applied" } : patch)),
    );
    setStatus(`Applied patch ${nextPatch.id}: ${nextPatch.label}`);
  }

  function handleKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    if (!document.nodes.length) return;
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
      setSelectedId(nextNode(document.nodes, selectedId, 1));
    }
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      setSelectedId(nextNode(document.nodes, selectedId, -1));
    }
    if (event.key === "Escape") {
      event.preventDefault();
      drillOut();
    }
  }

  return (
    <main className="hg-shell" onKeyDown={handleKeyDown} tabIndex={-1}>
      <section className="hg-appbar" aria-label="The Robot Draft application menu">
        <div className="hg-appbar__brand">
          <strong>The Robot Draft</strong>
          <span>{document.title}</span>
        </div>
        <nav className="hg-menu" aria-label="Application commands">
          {menuGroups.map((group) => (
            <button key={group.label} className="hg-menu__item" type="button" title={group.items.join(" / ")}>
              {group.label}
            </button>
          ))}
        </nav>
        <div className="hg-appbar__status" aria-label="Document metrics">
          <span>saved</span>
          <span>v{document.version}</span>
          <span>{document.nodes.length} elements</span>
        </div>
      </section>

      <section className="hg-tabbar" aria-label="Open model tabs">
        <button className="hg-tab is-active" type="button">
          {document.slug}
        </button>
        <button className="hg-tab" type="button">
          Unity parity fixture
        </button>
        <div className="hg-tabbar__hint">{status}</div>
      </section>

      <section className="hg-workspace" aria-label="Graph document workspace">
        <aside className="hg-panel hg-panel--left" aria-label="Creation palette and project controls">
          <div className="hg-panel__section">
            <label className="hg-label" htmlFor="graph-search">
              Search / jump
            </label>
            <input
              id="graph-search"
              className="hg-input"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="class, edge, package"
            />
            <p className="hg-help">{query.trim() ? matchingIds.size : document.nodes.length} matching nodes</p>
          </div>

          <div className="hg-panel__section">
            <p className="hg-label">3D authoring rail</p>
            <div className="hg-tool-grid" aria-label="3D UML authoring commands">
              <button className="hg-tool is-active" type="button" title="Select 3D node">
                Select
              </button>
              <button className="hg-tool" type="button" title="Add UML element">
                Add
              </button>
              <button className="hg-tool" type="button" title="Connect selected nodes">
                Connect
              </button>
              <button className="hg-tool" type="button" title="Delete selected element">
                Delete
              </button>
              <button className="hg-tool" type="button" title="Undo last model edit">
                Undo
              </button>
              <button className="hg-tool" type="button" title="Redo last model edit">
                Redo
              </button>
              <button className="hg-tool" type="button" title="Project 3D model to UML export">
                Project
              </button>
              <button className="hg-tool" type="button" title="Generate reviewed draft patches">
                AI Draft
              </button>
            </div>
            <button className="hg-command hg-command--primary" type="button" onClick={importFixture}>
              Import 3D UML fixture
            </button>
            <button className="hg-command" type="button" onClick={focusSelected}>
              Frame selected
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
            <p className="hg-label">Creation palette</p>
            <div className="hg-palette">
              {paletteGroups.map((group) => (
                <div key={group.label} className="hg-palette__group">
                  <strong>{group.label}</strong>
                  {group.items.map((item) => (
                    <button key={item} className="hg-palette__item" type="button" title={`Add ${item}`}>
                      <span aria-hidden="true" />
                      {item}
                    </button>
                  ))}
                </div>
              ))}
            </div>
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

          <div className="hg-panel__section">
            <p className="hg-label">Graph health</p>
            <dl className="hg-health">
              <div>
                <dt>Lanes</dt>
                <dd>{metrics.laneCount}</dd>
              </div>
              <div>
                <dt>Relations</dt>
                <dd>{metrics.crossLaneEdgeCount}</dd>
              </div>
              <div>
                <dt>Avg risk</dt>
                <dd>{metrics.averageRisk}</dd>
              </div>
            </dl>
          </div>
        </aside>

        <section className="hg-canvas-wrap" aria-label="Interactive graph renderer">
          <div className="hg-canvas-toolbar">
            <div>
              <strong>{focusId ? `Focused: ${document.nodes.find((node) => node.id === focusId)?.label}` : "3D Scene"}</strong>
              <span>Orbit drag; wheel dolly; WASD/RF free-fly; Q/E roll; F frames; Home recenters.</span>
            </div>
            <div className="hg-hud-actions" aria-label="Scene HUD controls">
              <button type="button" title="Open camera form">Camera...</button>
              <button type="button" onClick={recenter} title="Reset view">Reset</button>
              <button type="button" title="3D mode is active">3D On</button>
              <button type="button" title="Controls and shortcuts">? Help</button>
            </div>
          </div>
          <div className="hg-scene-status" aria-label="Scene mode">
            <span>Select</span>
            <span>layer {document.view?.activeLayer ?? 0}</span>
            <span>{metrics.hotNodeCount} hot</span>
            <strong>Unity-parity 3D UML</strong>
          </div>
          <TrdThreeScene
            document={document}
            selectedId={selectedNode?.id}
            focusId={focusId}
            tracedEdgeIds={tracedEdgeIds}
            onSelect={setSelectedId}
            onStatus={setStatus}
          />
        </section>

        <aside className="hg-panel hg-panel--right" aria-label="Selection detail panel">
          {selectedNode ? (
            <>
              <p className="hg-label">Inspector</p>
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
              <div className="hg-panel__section">
                <CollabStrip document={document} focusNodeId={focusId} selectedNodeId={selectedNode.id} />
              </div>
            </>
          ) : null}
        </aside>
      </section>
    </main>
  );
}
