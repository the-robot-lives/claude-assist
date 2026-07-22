"use client";

import { type ChangeEvent, type MouseEvent, useEffect, useMemo, useRef, useState } from "react";
import { graphMetrics, riskBandFor, searchNodes, traceNeighbors } from "@/lib/holograph/analysis";
import {
  createEmptyDocument,
  downloadText,
  exportCodeSkeleton,
  exportDot,
  exportMermaid,
  exportPlantUml,
  importCodeFiles,
  importPlantUml,
  readGraphDocumentJson,
} from "@/lib/holograph/document-io";
import { demoDocument } from "@/lib/holograph/fixture";
import type { GraphDocument, GraphEdge, GraphNode, NodeKind } from "@/lib/holograph/types";
import { TrdThreeScene } from "./trd-three-scene";

type CommandId =
  | "file.new"
  | "file.open"
  | "file.save"
  | "file.saveAs"
  | "file.importPlantUml"
  | "file.importCode"
  | "file.loadExample"
  | "edit.undo"
  | "edit.redo"
  | "edit.copy"
  | "edit.paste"
  | "edit.delete"
  | "add.class"
  | "add.interface"
  | "add.package"
  | "add.service"
  | "add.agent"
  | "add.database"
  | "layout.frameSelected"
  | "layout.frameAll"
  | "layout.reset"
  | "export.json"
  | "export.plantuml"
  | "export.mermaid"
  | "export.dot"
  | "export.code";

interface MenuItem {
  label: string;
  command: CommandId;
}

interface MenuGroup {
  label: string;
  items: MenuItem[];
}

interface ContextMenuState {
  x: number;
  y: number;
  nodeId: string | null;
}

const autosaveKey = "trd:vnext:active-document";
const clipboardKey = "trd:vnext:clipboard-node";

const emptyInitialDocument: GraphDocument = {
  id: "trd-local-untitled",
  slug: "untitled-3d-uml-model",
  title: "Untitled 3D UML model",
  version: 1,
  updatedAt: "2026-07-22T00:00:00.000Z",
  summary: "Empty The Robot Draft 3D UML workspace.",
  modelKind: "uml",
  view: { projection: "trd-3d-uml", activeLayer: 0 },
  nodes: [],
  edges: [],
};

const menuGroups: MenuGroup[] = [
  {
    label: "File",
    items: [
      { label: "New", command: "file.new" },
      { label: "Open...", command: "file.open" },
      { label: "Save", command: "file.save" },
      { label: "Save As...", command: "file.saveAs" },
      { label: "Import PlantUML...", command: "file.importPlantUml" },
      { label: "Import Code...", command: "file.importCode" },
      { label: "Load Unity Parity Example", command: "file.loadExample" },
    ],
  },
  {
    label: "Edit",
    items: [
      { label: "Undo", command: "edit.undo" },
      { label: "Redo", command: "edit.redo" },
      { label: "Copy", command: "edit.copy" },
      { label: "Paste", command: "edit.paste" },
      { label: "Delete", command: "edit.delete" },
    ],
  },
  {
    label: "Add",
    items: [
      { label: "Class", command: "add.class" },
      { label: "Interface", command: "add.interface" },
      { label: "Package", command: "add.package" },
      { label: "Service", command: "add.service" },
      { label: "Agent", command: "add.agent" },
      { label: "Datastore", command: "add.database" },
    ],
  },
  {
    label: "Layout",
    items: [
      { label: "Frame Selected", command: "layout.frameSelected" },
      { label: "Frame All", command: "layout.frameAll" },
      { label: "Reset View", command: "layout.reset" },
    ],
  },
  {
    label: "Export",
    items: [
      { label: "TRD JSON", command: "export.json" },
      { label: "PlantUML", command: "export.plantuml" },
      { label: "Mermaid", command: "export.mermaid" },
      { label: "DOT", command: "export.dot" },
      { label: "Code Skeleton", command: "export.code" },
    ],
  },
];

const paletteGroups = [
  { label: "UML", items: [{ label: "Class", command: "add.class" }, { label: "Interface", command: "add.interface" }] },
  { label: "Architecture", items: [{ label: "Package", command: "add.package" }, { label: "Service", command: "add.service" }, { label: "Datastore", command: "add.database" }, { label: "Agent", command: "add.agent" }] },
  { label: "Round-trip", items: [{ label: "Import code", command: "file.importCode" }, { label: "Export code", command: "export.code" }, { label: "PlantUML", command: "export.plantuml" }] },
] satisfies Array<{ label: string; items: MenuItem[] }>;

function scoreLabel(value: number) {
  return riskBandFor(value);
}

function nextNode(nodes: GraphNode[], currentId: string, direction: 1 | -1) {
  const index = nodes.findIndex((node) => node.id === currentId);
  const nextIndex = index < 0 ? 0 : (index + direction + nodes.length) % nodes.length;
  return nodes[nextIndex]?.id ?? currentId;
}

function nodeTone(node: GraphNode) {
  if (node.kind === "system") return "node-system";
  if (node.kind === "agent") return "node-agent";
  if (node.kind === "database") return "node-store";
  if (node.status === "hot") return "node-hot";
  if (node.status === "review") return "node-review";
  return "node-default";
}

function slugFor(value: string) {
  return (
    value
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60) || "element"
  );
}

function metricsFor(label: string): GraphNode["metrics"] {
  const seed = Array.from(label).reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return { complexity: 20 + (seed % 40), churn: 10 + (seed % 24), risk: 12 + (seed % 34) };
}

function elementLabel(kind: NodeKind, count: number) {
  if (kind === "database") return `Datastore${count}`;
  return `${kind[0].toUpperCase()}${kind.slice(1)}${count}`;
}

function filenameFor(document: GraphDocument, extension: string) {
  return `${document.slug || slugFor(document.title)}.${extension}`;
}

function withDocumentUpdate(document: GraphDocument, patch: Partial<GraphDocument>): GraphDocument {
  return {
    ...document,
    ...patch,
    version: document.version + 1,
    updatedAt: new Date().toISOString(),
  };
}

export function HoloGraphWorkspace() {
  const graphFileInputRef = useRef<HTMLInputElement | null>(null);
  const plantUmlInputRef = useRef<HTMLInputElement | null>(null);
  const codeInputRef = useRef<HTMLInputElement | null>(null);
  const [document, setDocument] = useState<GraphDocument>(emptyInitialDocument);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [focusId, setFocusId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [traceEnabled, setTraceEnabled] = useState(true);
  const [status, setStatus] = useState("New empty 3D UML workspace. Open or import a model to begin.");
  const [activeMenu, setActiveMenu] = useState<string | null>(null);
  const [contextMenu, setContextMenu] = useState<ContextMenuState | null>(null);
  const [history, setHistory] = useState<GraphDocument[]>([]);
  const [redoStack, setRedoStack] = useState<GraphDocument[]>([]);
  const [loadedFromStorage, setLoadedFromStorage] = useState(false);

  useEffect(() => {
    const saved = window.localStorage.getItem(autosaveKey);
    if (saved) {
      try {
        const restored = readGraphDocumentJson(saved);
        setDocument(restored);
        setSelectedId(restored.nodes[0]?.id ?? null);
        setStatus(`Restored autosaved model: ${restored.title}`);
      } catch {
        setStatus("Autosave was unreadable; started a new empty 3D UML workspace.");
      }
    }
    setLoadedFromStorage(true);
  }, []);

  useEffect(() => {
    if (!loadedFromStorage) return;
    window.localStorage.setItem(autosaveKey, JSON.stringify(document));
  }, [document, loadedFromStorage]);

  const metrics = useMemo(() => graphMetrics(document), [document]);
  const selectedNode = selectedId ? document.nodes.find((node) => node.id === selectedId) ?? null : null;
  const matchingNodes = useMemo(() => searchNodes(document, query), [document, query]);
  const matchingIds = new Set(matchingNodes.map((node) => node.id));
  const trace = useMemo(
    () => (selectedNode ? traceNeighbors(document, selectedNode.id) : null),
    [document, selectedNode],
  );
  const tracedEdgeIds = new Set(traceEnabled && trace ? trace.edgeIds : []);

  function commitDocument(next: GraphDocument, message: string, pushHistory = true) {
    setDocument((current) => {
      if (pushHistory) setHistory((items) => [...items, current].slice(-50));
      return next;
    });
    setRedoStack([]);
    setSelectedId(next.nodes[0]?.id ?? null);
    setFocusId(null);
    setStatus(message);
  }

  function replaceDocument(next: GraphDocument, message: string) {
    setHistory([]);
    setRedoStack([]);
    setDocument(next);
    setSelectedId(next.nodes[0]?.id ?? null);
    setFocusId(null);
    setStatus(message);
  }

  function addNode(kind: NodeKind) {
    const count = document.nodes.filter((node) => node.kind === kind).length + 1;
    const label = elementLabel(kind, count);
    const usedIds = new Set(document.nodes.map((node) => node.id));
    const baseId = `${kind}-${slugFor(label)}`;
    let id = baseId;
    let suffix = 2;
    while (usedIds.has(id)) {
      id = `${baseId}-${suffix}`;
      suffix += 1;
    }
    const parentId = selectedNode?.kind === "package" || selectedNode?.kind === "system" ? selectedNode.id : undefined;
    const node: GraphNode = {
      id,
      label,
      kind,
      parentId,
      stereotype: kind,
      description: `New ${kind} element.`,
      uml: {
        elementType: kind === "database" ? "DataStore" : kind[0].toUpperCase() + kind.slice(1),
        visibility: "public",
        attributes: kind === "class" ? ["+ id : ElementId"] : [],
        operations: kind === "class" || kind === "interface" ? ["+ update()"] : [],
      },
      metrics: metricsFor(label),
      members: [],
      status: "draft",
    };
    const edge: GraphEdge | null = parentId
      ? { id: `contains-${parentId}-${id}`, sourceId: parentId, targetId: id, kind: "contains", label: "contains" }
      : null;
    commitDocument(
      withDocumentUpdate(document, {
        nodes: [...document.nodes, node],
        edges: edge ? [...document.edges, edge] : document.edges,
      }),
      `Added ${label}`,
    );
    setSelectedId(id);
  }

  function deleteSelected() {
    if (!selectedNode) {
      setStatus("Nothing selected to delete.");
      return;
    }
    const removedIds = new Set<string>([selectedNode.id]);
    let changed = true;
    while (changed) {
      changed = false;
      for (const node of document.nodes) {
        if (node.parentId && removedIds.has(node.parentId) && !removedIds.has(node.id)) {
          removedIds.add(node.id);
          changed = true;
        }
      }
    }
    commitDocument(
      withDocumentUpdate(document, {
        nodes: document.nodes.filter((node) => !removedIds.has(node.id)),
        edges: document.edges.filter((edge) => !removedIds.has(edge.sourceId) && !removedIds.has(edge.targetId)),
      }),
      `Deleted ${selectedNode.label}`,
    );
  }

  function copySelected() {
    if (!selectedNode) {
      setStatus("Nothing selected to copy.");
      return;
    }
    window.localStorage.setItem(clipboardKey, JSON.stringify(selectedNode));
    setStatus(`Copied ${selectedNode.label}`);
  }

  function pasteNode() {
    const stored = window.localStorage.getItem(clipboardKey);
    if (!stored) {
      setStatus("Clipboard is empty.");
      return;
    }
    try {
      const node = JSON.parse(stored) as GraphNode;
      const id = `${node.id}-copy-${Date.now().toString(36)}`;
      commitDocument(
        withDocumentUpdate(document, {
          nodes: [...document.nodes, { ...node, id, label: `${node.label} Copy`, status: "draft" }],
        }),
        `Pasted ${node.label}`,
      );
      setSelectedId(id);
    } catch {
      setStatus("Clipboard did not contain a valid TRD node.");
    }
  }

  function focusSelected() {
    if (!selectedNode) {
      setStatus("Select an element to frame it.");
      return;
    }
    setFocusId(selectedNode.id);
    setStatus(`Framed ${selectedNode.label}`);
  }

  function recenter() {
    setFocusId(null);
    setSelectedId(document.nodes[0]?.id ?? null);
    setStatus("Recentered to whole model.");
  }

  function undo() {
    const previous = history.at(-1);
    if (!previous) {
      setStatus("Nothing to undo.");
      return;
    }
    setRedoStack((items) => [document, ...items].slice(0, 50));
    setHistory((items) => items.slice(0, -1));
    setDocument(previous);
    setSelectedId(previous.nodes[0]?.id ?? null);
    setStatus("Undo applied.");
  }

  function redo() {
    const next = redoStack[0];
    if (!next) {
      setStatus("Nothing to redo.");
      return;
    }
    setHistory((items) => [...items, document].slice(-50));
    setRedoStack((items) => items.slice(1));
    setDocument(next);
    setSelectedId(next.nodes[0]?.id ?? null);
    setStatus("Redo applied.");
  }

  function exportDocument(command: CommandId) {
    if (command === "export.json" || command === "file.save" || command === "file.saveAs") {
      downloadText(filenameFor(document, "trd.json"), JSON.stringify(document, null, 2), "application/json");
      setStatus(`Saved ${document.title} as TRD JSON.`);
      return;
    }
    if (command === "export.plantuml") {
      downloadText(filenameFor(document, "puml"), exportPlantUml(document), "text/plain");
      setStatus("Exported PlantUML.");
      return;
    }
    if (command === "export.mermaid") {
      downloadText(filenameFor(document, "mmd"), exportMermaid(document), "text/plain");
      setStatus("Exported Mermaid class diagram.");
      return;
    }
    if (command === "export.dot") {
      downloadText(filenameFor(document, "dot"), exportDot(document), "text/vnd.graphviz");
      setStatus("Exported DOT graph.");
      return;
    }
    if (command === "export.code" || command === "file.importCode") {
      downloadText(filenameFor(document, "cs"), exportCodeSkeleton(document), "text/plain");
      setStatus("Exported code skeleton.");
    }
  }

  function executeCommand(command: CommandId) {
    setActiveMenu(null);
    setContextMenu(null);
    if (command === "file.new") replaceDocument(createEmptyDocument(), "Created a new empty 3D UML workspace.");
    else if (command === "file.open") graphFileInputRef.current?.click();
    else if (command === "file.importPlantUml") plantUmlInputRef.current?.click();
    else if (command === "file.importCode") codeInputRef.current?.click();
    else if (command === "file.loadExample") replaceDocument(demoDocument, "Loaded the Unity parity example model.");
    else if (command === "edit.undo") undo();
    else if (command === "edit.redo") redo();
    else if (command === "edit.copy") copySelected();
    else if (command === "edit.paste") pasteNode();
    else if (command === "edit.delete") deleteSelected();
    else if (command.startsWith("add.")) addNode(command.replace("add.", "") as NodeKind);
    else if (command === "layout.frameSelected") focusSelected();
    else if (command === "layout.frameAll" || command === "layout.reset") recenter();
    else exportDocument(command);
  }

  async function readTextFile(file: File) {
    return { name: file.name, text: await file.text() };
  }

  async function handleGraphFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = "";
    if (!file) return;
    try {
      replaceDocument(readGraphDocumentJson(await file.text()), `Opened ${file.name}`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : `Could not open ${file.name}.`);
    }
  }

  async function handlePlantUmlFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = "";
    if (!file) return;
    try {
      replaceDocument(importPlantUml(await file.text(), file.name), `Imported PlantUML from ${file.name}`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : `Could not import ${file.name}.`);
    }
  }

  async function handleCodeFiles(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.currentTarget.files ?? []);
    event.currentTarget.value = "";
    if (!files.length) return;
    try {
      const payloads = await Promise.all(files.map(readTextFile));
      replaceDocument(importCodeFiles(payloads), `Imported ${files.length} source file${files.length === 1 ? "" : "s"}.`);
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "Could not import code files.");
    }
  }

  function handleKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    if (event.metaKey || event.ctrlKey) {
      if (event.key.toLowerCase() === "o") {
        event.preventDefault();
        executeCommand("file.open");
      }
      if (event.key.toLowerCase() === "s") {
        event.preventDefault();
        executeCommand(event.shiftKey ? "file.saveAs" : "file.save");
      }
      if (event.key.toLowerCase() === "z") {
        event.preventDefault();
        executeCommand(event.shiftKey ? "edit.redo" : "edit.undo");
      }
      if (event.key.toLowerCase() === "c") {
        event.preventDefault();
        executeCommand("edit.copy");
      }
      if (event.key.toLowerCase() === "v") {
        event.preventDefault();
        executeCommand("edit.paste");
      }
    }
    if (event.key === "Delete") deleteSelected();
    if (event.key === "f" || event.key === "F") focusSelected();
    if (event.key === "Home") recenter();
    if (event.key === "ArrowRight" && document.nodes.length) setSelectedId(nextNode(document.nodes, selectedId ?? "", 1));
    if (event.key === "ArrowLeft" && document.nodes.length) setSelectedId(nextNode(document.nodes, selectedId ?? "", -1));
  }

  function openCanvasContextMenu(event: MouseEvent<HTMLElement>) {
    event.preventDefault();
    setContextMenu({ x: event.clientX, y: event.clientY, nodeId: selectedId });
  }

  return (
    <main className="hg-shell" onKeyDown={handleKeyDown} onClick={() => setContextMenu(null)} tabIndex={-1}>
      <input ref={graphFileInputRef} type="file" accept=".json,.trd,.trd.json,application/json" hidden onChange={handleGraphFile} />
      <input ref={plantUmlInputRef} type="file" accept=".puml,.plantuml,.txt,text/plain" hidden onChange={handlePlantUmlFile} />
      <input ref={codeInputRef} type="file" accept=".cs,.ts,.tsx,.js,.jsx,.java,.kt,.swift,.py,.go,.rs,.cpp,.h,.hpp,.txt" multiple hidden onChange={handleCodeFiles} />

      <section className="hg-appbar" aria-label="The Robot Draft application menu">
        <div className="hg-appbar__brand">
          <strong>The Robot Draft</strong>
          <span>{document.title}</span>
        </div>
        <nav className="hg-menu" aria-label="Application commands">
          {menuGroups.map((group) => (
            <div key={group.label} className="hg-menu__group">
              <button
                className="hg-menu__item"
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  setActiveMenu(activeMenu === group.label ? null : group.label);
                }}
              >
                {group.label}
              </button>
              {activeMenu === group.label ? (
                <div className="hg-menu__dropdown" role="menu">
                  {group.items.map((item) => (
                    <button key={item.command} type="button" role="menuitem" onClick={() => executeCommand(item.command)}>
                      {item.label}
                    </button>
                  ))}
                </div>
              ) : null}
            </div>
          ))}
        </nav>
        <div className="hg-appbar__status" aria-label="Document metrics">
          <span>autosaved</span>
          <span>v{document.version}</span>
          <span>{document.nodes.length} elements</span>
        </div>
      </section>

      <section className="hg-tabbar" aria-label="Open model tabs">
        <button className="hg-tab is-active" type="button">
          {document.slug}
        </button>
        <div className="hg-tabbar__hint">{status}</div>
      </section>

      <section className="hg-workspace" aria-label="3D UML document workspace">
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
              <button className="hg-tool" type="button" onClick={() => executeCommand("add.class")} title="Add UML class">
                Add
              </button>
              <button className="hg-tool" type="button" onClick={() => setStatus("Connect mode is next: use import/export relationships for this checkpoint.")} title="Connect selected nodes">
                Connect
              </button>
              <button className="hg-tool" type="button" onClick={() => executeCommand("edit.delete")} title="Delete selected element">
                Delete
              </button>
              <button className="hg-tool" type="button" onClick={() => executeCommand("edit.undo")} title="Undo last model edit">
                Undo
              </button>
              <button className="hg-tool" type="button" onClick={() => executeCommand("edit.redo")} title="Redo last model edit">
                Redo
              </button>
              <button className="hg-tool" type="button" onClick={() => executeCommand("export.plantuml")} title="Project 3D model to UML export">
                Project
              </button>
              <button className="hg-tool" type="button" onClick={() => executeCommand("file.importCode")} title="Import source files into model">
                Import
              </button>
            </div>
            <button className="hg-command hg-command--primary" type="button" onClick={() => executeCommand("file.open")}>
              Open TRD model
            </button>
            <button className="hg-command" type="button" onClick={() => executeCommand("file.importCode")}>
              Import code
            </button>
            <button className="hg-command" type="button" onClick={() => executeCommand("export.code")}>
              Export code
            </button>
            <button className="hg-command" type="button" onClick={() => executeCommand("layout.frameSelected")} disabled={!selectedNode}>
              Frame selected
            </button>
            <label className="hg-toggle">
              <input type="checkbox" checked={traceEnabled} onChange={(event) => setTraceEnabled(event.target.checked)} />
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
                    <button key={item.command} className="hg-palette__item" type="button" onClick={() => executeCommand(item.command)} title={item.label}>
                      <span aria-hidden="true" />
                      {item.label}
                    </button>
                  ))}
                </div>
              ))}
            </div>
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

        <section className="hg-canvas-wrap" aria-label="Interactive 3D UML renderer" onContextMenu={openCanvasContextMenu}>
          <div className="hg-canvas-toolbar">
            <div>
              <strong>{focusId ? `Focused: ${document.nodes.find((node) => node.id === focusId)?.label}` : "3D Scene"}</strong>
              <span>Orbit drag; wheel dolly; WASD/RF free-fly; Q/E roll; right-click opens commands.</span>
            </div>
            <div className="hg-hud-actions" aria-label="Scene HUD controls">
              <button type="button" onClick={() => setStatus("Camera HUD form is queued after file round-trip parity.")}>Camera...</button>
              <button type="button" onClick={recenter}>Reset</button>
              <button type="button">3D On</button>
              <button type="button" onClick={() => setStatus("Shortcuts: Cmd+O open, Cmd+S save, Cmd+Z undo, F frame, Home recenter.")}>
                ? Help
              </button>
            </div>
          </div>
          <div className="hg-scene-status" aria-label="Scene mode">
            <span>Select</span>
            <span>layer {document.view?.activeLayer ?? 0}</span>
            <span>{metrics.hotNodeCount} hot</span>
            <strong>3D UML</strong>
          </div>
          {!document.nodes.length ? (
            <div className="hg-empty-state">
              <strong>Empty 3D UML workspace</strong>
              <button type="button" onClick={() => executeCommand("file.open")}>Open TRD JSON</button>
              <button type="button" onClick={() => executeCommand("file.importCode")}>Import code</button>
              <button type="button" onClick={() => executeCommand("file.importPlantUml")}>Import PlantUML</button>
            </div>
          ) : null}
          <TrdThreeScene
            document={document}
            selectedId={selectedNode?.id}
            focusId={focusId}
            tracedEdgeIds={tracedEdgeIds}
            onSelect={setSelectedId}
            onStatus={setStatus}
          />
        </section>

        <aside className="hg-panel hg-panel--right" aria-label="Inspector panel">
          <p className="hg-label">Inspector</p>
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
                  {(selectedNode.members?.length ? selectedNode.members : selectedNode.uml?.attributes?.concat(selectedNode.uml.operations ?? []) ?? ["No members recorded"]).map((member) => (
                    <li key={member}>{member}</li>
                  ))}
                </ul>
              </div>
              <div className="hg-panel__section">
                <p className="hg-label">Round-trip</p>
                <button className="hg-command" type="button" onClick={() => executeCommand("export.plantuml")}>
                  Export PlantUML
                </button>
                <button className="hg-command" type="button" onClick={() => executeCommand("export.code")}>
                  Export code skeleton
                </button>
                <button className="hg-command hg-command--primary" type="button" onClick={() => executeCommand("file.save")}>
                  Save TRD JSON
                </button>
              </div>
            </>
          ) : (
            <p className="hg-description">No element selected. Add an element, open a TRD model, or import code/PlantUML.</p>
          )}
        </aside>
      </section>

      {contextMenu ? (
        <div className="hg-context-menu" style={{ left: contextMenu.x, top: contextMenu.y }} role="menu" onClick={(event) => event.stopPropagation()}>
          <button type="button" role="menuitem" onClick={() => executeCommand("add.class")}>Add Class</button>
          <button type="button" role="menuitem" onClick={() => executeCommand("add.interface")}>Add Interface</button>
          <button type="button" role="menuitem" onClick={() => executeCommand("file.importCode")}>Import Code...</button>
          <button type="button" role="menuitem" onClick={() => executeCommand("file.importPlantUml")}>Import PlantUML...</button>
          <button type="button" role="menuitem" onClick={() => executeCommand("export.plantuml")}>Export PlantUML</button>
          <button type="button" role="menuitem" onClick={() => executeCommand("export.code")}>Export Code Skeleton</button>
          <button type="button" role="menuitem" disabled={!contextMenu.nodeId} onClick={() => executeCommand("edit.delete")}>Delete Selection</button>
        </div>
      ) : null}
    </main>
  );
}
