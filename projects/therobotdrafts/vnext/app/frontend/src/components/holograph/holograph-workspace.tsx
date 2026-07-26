"use client";

import {
  type ChangeEvent,
  type MouseEvent,
  type RefObject,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { searchNodes, traceNeighbors } from "@/lib/holograph/analysis";
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
  relationshipEdgeKind,
  relationshipStyle,
  skeletonLanguages,
  type SkeletonLanguage,
  UML_RELATIONSHIPS,
  type UmlRelationship,
} from "@/lib/holograph/document-io";
import { exportTrdYaml, importTrdYaml, looksLikeTrdYaml } from "@/lib/holograph/trd-yaml";
import { demoDocument } from "@/lib/holograph/fixture";
import {
  DocVersionConflictError,
  newClientEventId,
  type DocPatchOperation,
} from "@/lib/holograph/doc-store";
import { hasActiveDraft, readActiveDraft, writeActiveDraft } from "@/lib/holograph/local-draft-store";
import { useDocStore } from "@/lib/holograph/use-doc-store";
import type { GraphDocument, GraphEdge, GraphNode, NodeKind } from "@/lib/holograph/types";
import { toast } from "sonner";
import { TrdThreeScene, type TrdSceneHandle } from "./trd-three-scene";
import "./chrome/concept-d.css";
import { BrowserDock, type BrowserTab, type DocumentSummary, type RecentEntry } from "./chrome/BrowserDock";
import { CommandPalette, type PaletteCommand } from "./chrome/CommandPalette";
import { ContextToolbar, type ToolMode } from "./chrome/ContextToolbar";
import { IconRail } from "./chrome/IconRail";
import { Inspector } from "./chrome/Inspector";
import { MenuBar } from "./chrome/MenuBar";
import { PaletteDock, TRD_KIND_DRAG_TYPE } from "./chrome/PaletteDock";
import { formatCameraPose, StatusStrip, type StatusStripProps } from "./chrome/StatusStrip";
import {
  buildPaletteCommands,
  ELEMENT_KINDS,
  KIND_BROWSER_ENTRIES,
  type ElementKindKey,
  type MenuEntry,
  type TrdCommandId,
} from "./chrome/menu-data";

const clipboardKey = "trd:vnext:clipboard-node";
const recentsKey = "trd:vnext:recent-models";
const commandMruKey = "trd:vnext:command-mru";

const RECENTS_LIMIT = 6;
const COMMAND_MRU_LIMIT = 12;
/** Edits settle into one patch batch rather than one per keystroke. */
const AUTOSAVE_DEBOUNCE_MS = 1200;

/** Derived once: the menu IA is static, so the palette's command catalogue is too. */
const MENU_COMMANDS = buildPaletteCommands();

interface ContextMenuState {
  x: number;
  y: number;
  nodeId: string | null;
}

interface RecentRecord extends RecentEntry {
  document: GraphDocument;
}

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

const SELECT_HINT = "Click a node to select · C for Connect mode · ⌘K for commands";

/** Owns the 4Hz camera poll so the pose ticker re-renders the 26px band, not the shell.
 * The three.js camera is imperative and exposes no React-facing change event. */
function LiveStatusStrip({
  sceneHandleRef,
  ...rest
}: Omit<StatusStripProps, "cameraPose"> & { sceneHandleRef: RefObject<TrdSceneHandle | null> }) {
  const [cameraPose, setCameraPose] = useState("cam — / — · d —");

  useEffect(() => {
    function read() {
      const pose = sceneHandleRef.current?.getCameraPose();
      if (pose) setCameraPose(formatCameraPose(pose.yaw, pose.pitch, pose.distance));
    }
    read();
    const timer = window.setInterval(read, 250);
    return () => window.clearInterval(timer);
  }, [sceneHandleRef]);

  return <StatusStrip {...rest} cameraPose={cameraPose} />;
}

function nextNode(nodes: GraphNode[], currentId: string, direction: 1 | -1) {
  const index = nodes.findIndex((node) => node.id === currentId);
  const nextIndex = index < 0 ? 0 : (index + direction + nodes.length) % nodes.length;
  return nodes[nextIndex]?.id ?? currentId;
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

/** Identifies the stored document the workspace is currently bound to, and the store
 * version its pending edits are based on. Null while the open model is unpublished. */
interface RemoteBinding {
  id: string;
  version: number;
}

/** The inspector edits a node through one generic callback, so the semantic op is read
 * back off the result — only renames and reparents have one. */
function inspectorOp(before: GraphNode, after: GraphNode): DocPatchOperation | undefined {
  if (before.label !== after.label) {
    return { type: "rename", targetId: after.id, label: after.label };
  }
  if (before.parentId !== after.parentId) {
    return { type: "reparent", targetId: after.id, label: after.parentId ?? "root" };
  }
  return undefined;
}

function readJson<T>(key: string, fallback: T): T {
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

export function HoloGraphWorkspace() {
  const graphFileInputRef = useRef<HTMLInputElement | null>(null);
  const plantUmlInputRef = useRef<HTMLInputElement | null>(null);
  const codeInputRef = useRef<HTMLInputElement | null>(null);
  const sceneHandleRef = useRef<TrdSceneHandle | null>(null);
  const outlineFilterRef = useRef<HTMLInputElement | null>(null);
  const inspectorNameRef = useRef<HTMLInputElement | null>(null);
  // The three.js scene listens on its own canvas, so a node hit lands here before the
  // React click bubbles to the viewport wrapper — that ordering is what lets Place mode
  // tell "clicked empty space" from "clicked a node" without touching the scene.
  const sceneHitAtRef = useRef(0);

  // ---- document + model state
  const [document, setDocument] = useState<GraphDocument>(emptyInitialDocument);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [focusId, setFocusId] = useState<string | null>(null);
  const [connectSourceId, setConnectSourceId] = useState<string | null>(null);
  const [history, setHistory] = useState<GraphDocument[]>([]);
  const [redoStack, setRedoStack] = useState<GraphDocument[]>([]);
  const [loadedFromStorage, setLoadedFromStorage] = useState(false);

  // ---- tool state
  const [mode, setModeState] = useState<ToolMode>("select");
  const [armedKind, setArmedKind] = useState<ElementKindKey | null>(null);
  const [relationshipType, setRelationshipType] = useState<UmlRelationship>("association");
  const [traceEnabled, setTraceEnabled] = useState(true);
  const [hint, setHint] = useState(SELECT_HINT);

  // ---- chrome state
  const [openMenu, setOpenMenu] = useState<string | null>(null);
  const [contextMenu, setContextMenu] = useState<ContextMenuState | null>(null);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [kindBrowserOpen, setKindBrowserOpen] = useState(false);
  const [kindBrowserFilter, setKindBrowserFilter] = useState("");
  const [cameraForm, setCameraForm] = useState<Record<
    "yaw" | "pitch" | "roll" | "x" | "y" | "z" | "distance",
    string
  > | null>(null);
  const [browserCollapsed, setBrowserCollapsed] = useState(false);
  const [inspectorCollapsed, setInspectorCollapsed] = useState(false);
  const [paletteDockCollapsed, setPaletteDockCollapsed] = useState(false);
  const [statusVisible, setStatusVisible] = useState(true);
  const [focusMode, setFocusMode] = useState(false);
  const [browserTab, setBrowserTab] = useState<BrowserTab>("files");
  const [query, setQuery] = useState("");

  // ---- browser dock data
  const [documents, setDocuments] = useState<DocumentSummary[]>([]);
  const [recents, setRecents] = useState<RecentRecord[]>([]);
  const [commandMru, setCommandMru] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);

  // ---- persistence
  const { store, ready: storeReady, fallbackReason } = useDocStore();
  const [remote, setRemote] = useState<RemoteBinding | null>(null);
  const [saveState, setSaveState] = useState<"idle" | "saving" | "error">("idle");
  // The autosave timer fires outside React's render cycle, so everything it reads has to
  // be available through a ref rather than a captured render value.
  const documentRef = useRef(document);
  documentRef.current = document;
  const storeRef = useRef(store);
  storeRef.current = store;
  const remoteRef = useRef(remote);
  remoteRef.current = remote;
  const pendingOpsRef = useRef<DocPatchOperation[]>([]);
  const autosaveTimerRef = useRef<number | null>(null);

  useEffect(() => {
    const restored = readActiveDraft();
    if (restored) {
      setDocument(restored);
      setSelectedId(restored.nodes[0]?.id ?? null);
      setHint(`Restored autosaved model: ${restored.title}`);
    } else if (hasActiveDraft()) {
      setHint("Autosave was unreadable; started a new empty 3D UML workspace.");
    }
    setRecents(readJson<RecentRecord[]>(recentsKey, []));
    setCommandMru(readJson<string[]>(commandMruKey, []));
    setLoadedFromStorage(true);
  }, []);

  // Crash recovery runs in both storage modes: a reload that beats the debounced patch
  // batch still finds the in-progress model.
  useEffect(() => {
    if (!loadedFromStorage) return;
    writeActiveDraft(document);
  }, [document, loadedFromStorage]);

  const refreshDocuments = useCallback(() => {
    storeRef.current
      .list()
      .then(setDocuments)
      .catch(() => setDocuments([]));
  }, []);

  useEffect(() => {
    if (!storeReady) return;
    let cancelled = false;
    setBusy(true);
    store
      .list()
      .then((rows) => {
        if (!cancelled) setDocuments(rows);
      })
      .catch(() => {
        if (!cancelled) setDocuments([]);
      })
      .finally(() => {
        if (!cancelled) setBusy(false);
      });
    return () => {
      cancelled = true;
    };
  }, [store, storeReady]);

  useEffect(() => {
    if (fallbackReason) setHint(`Working offline: ${fallbackReason}. Models stay in this browser.`);
  }, [fallbackReason]);

  useEffect(
    () => () => {
      if (autosaveTimerRef.current !== null) window.clearTimeout(autosaveTimerRef.current);
    },
    [],
  );

  const selectedNode = selectedId ? document.nodes.find((node) => node.id === selectedId) ?? null : null;
  // searchNodes is a search primitive and returns nothing for a blank query, but an
  // unfiltered Outline should list the whole loaded model.
  const matchingNodes = useMemo(
    () => (query.trim() ? searchNodes(document, query) : document.nodes),
    [document, query]
  );
  const trace = useMemo(
    () => (selectedNode ? traceNeighbors(document, selectedNode.id) : null),
    [document, selectedNode],
  );
  // Memoized: a fresh Set every render is a new identity in the scene effect's deps and
  // would tear down / rebuild the whole WebGL scene on every workspace render.
  const tracedEdgeIds = useMemo(() => new Set(traceEnabled && trace ? trace.edgeIds : []), [traceEnabled, trace]);

  function persistRecents(next: RecentRecord[]) {
    setRecents(next);
    try {
      window.localStorage.setItem(recentsKey, JSON.stringify(next));
    } catch {
      /* quota — the MRU is a convenience, never a source of truth */
    }
  }

  function pushRecent(next: GraphDocument) {
    const record: RecentRecord = {
      id: next.id,
      slug: next.slug,
      title: next.title,
      nodeCount: next.nodes.length,
      savedAt: new Date().toISOString(),
      document: next,
    };
    persistRecents([record, ...recents.filter((entry) => entry.id !== next.id)].slice(0, RECENTS_LIMIT));
  }

  function retainSelection(next: GraphDocument) {
    setSelectedId((current) => (current && next.nodes.some((node) => node.id === current) ? current : null));
  }

  function cancelAutosave() {
    if (autosaveTimerRef.current !== null) {
      window.clearTimeout(autosaveTimerRef.current);
      autosaveTimerRef.current = null;
    }
  }

  /** Last-write-wins recovery: reload whatever the store now holds and say so. There is
   * deliberately no merge UI — see the plan's conflict policy. */
  async function reloadAfterConflict(id: string, currentVersion?: number) {
    pendingOpsRef.current = [];
    try {
      const latest = await storeRef.current.load(id);
      bindDocument(latest, `Reloaded ${latest.title} — another session saved a newer version`, {
        id,
        version: latest.version,
      });
      setSaveState("idle");
      toast.warning("Model reloaded from the server", {
        description: `Another session saved v${currentVersion ?? latest.version}; your unsaved edits were replaced.`,
      });
    } catch {
      setSaveState("error");
      setHint("Could not reload the server copy — your edits are still in this browser.");
    }
  }

  async function flushAutosave() {
    const target = remoteRef.current;
    const activeStore = storeRef.current;
    if (!target || activeStore.kind !== "cloud") return;

    const operations = pendingOpsRef.current;
    pendingOpsRef.current = [];
    setSaveState("saving");
    try {
      const result = await activeStore.applyPatchBatch(target.id, {
        clientEventId: newClientEventId(),
        baseVersion: target.version,
        operations,
        document: documentRef.current,
      });
      setRemote({ id: result.documentId, version: result.version });
      setSaveState("idle");
    } catch (error) {
      if (error instanceof DocVersionConflictError) {
        await reloadAfterConflict(target.id, error.currentVersion);
        return;
      }
      setSaveState("error");
      setHint(error instanceof Error ? `Autosave failed: ${error.message}` : "Autosave failed.");
    }
  }

  /** Queues a debounced patch batch for the bound document. Unbound models (a new file,
   * an import, or a logged-out session) only get the local draft write. */
  function scheduleAutosave(op?: DocPatchOperation) {
    if (op) pendingOpsRef.current = [...pendingOpsRef.current, op];
    if (!remoteRef.current || storeRef.current.kind !== "cloud") return;
    cancelAutosave();
    autosaveTimerRef.current = window.setTimeout(() => {
      autosaveTimerRef.current = null;
      void flushAutosave();
    }, AUTOSAVE_DEBOUNCE_MS);
  }

  function commitDocument(
    next: GraphDocument,
    message: string,
    options?: { pushHistory?: boolean; selectId?: string | null; op?: DocPatchOperation },
  ) {
    setDocument((current) => {
      if (options?.pushHistory ?? true) setHistory((items) => [...items, current].slice(-50));
      return next;
    });
    setRedoStack([]);
    if (options?.selectId !== undefined) setSelectedId(options.selectId);
    else retainSelection(next);
    setFocusId(null);
    setHint(message);
    documentRef.current = next;
    scheduleAutosave(options?.op);
  }

  /** Swaps in a different model. The store binding does not follow automatically: an
   * imported or brand-new model is unpublished until an explicit Save, so autosave can
   * never write it over whichever document was open before. */
  function bindDocument(next: GraphDocument, message: string, binding: RemoteBinding | null) {
    cancelAutosave();
    pendingOpsRef.current = [];
    setRemote(binding);
    remoteRef.current = binding;
    setHistory([]);
    setRedoStack([]);
    setDocument(next);
    documentRef.current = next;
    setSelectedId(next.nodes[0]?.id ?? null);
    setFocusId(null);
    setHint(message);
    setSaveState("idle");
    pushRecent(next);
  }

  function replaceDocument(next: GraphDocument, message: string) {
    bindDocument(next, message, null);
  }

  function addNode(kind: NodeKind, at?: { x: number; y: number; z: number }) {
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
      trd3d: at ? { position: at, authored: true } : undefined,
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
      at ? `Placed ${label}` : `Added ${label}`,
      { selectId: id, op: { type: "add_node", targetId: id, label } },
    );
  }

  function deleteSelected() {
    if (!selectedNode) {
      setHint("Nothing selected to delete.");
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
      `Removed ${selectedNode.label} from the model`,
      { selectId: null, op: { type: "delete", targetId: selectedNode.id, label: selectedNode.label } },
    );
    if (connectSourceId && removedIds.has(connectSourceId)) setConnectSourceId(null);
  }

  function copySelected() {
    if (!selectedNode) {
      setHint("Nothing selected to copy.");
      return;
    }
    window.localStorage.setItem(clipboardKey, JSON.stringify(selectedNode));
    setHint(`Copied ${selectedNode.label}`);
  }

  function pasteNode() {
    const stored = window.localStorage.getItem(clipboardKey);
    if (!stored) {
      setHint("Clipboard is empty.");
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
        { selectId: id, op: { type: "add_node", targetId: id, label: `${node.label} Copy` } },
      );
    } catch {
      setHint("Clipboard did not contain a valid TRD node.");
    }
  }

  function duplicateSelected() {
    if (!selectedNode) {
      setHint("Nothing selected to duplicate.");
      return;
    }
    const id = `${selectedNode.id}-copy-${Date.now().toString(36)}`;
    commitDocument(
      withDocumentUpdate(document, {
        nodes: [...document.nodes, { ...selectedNode, id, label: `${selectedNode.label} Copy`, status: "draft" }],
      }),
      `Duplicated ${selectedNode.label}`,
      { selectId: id, op: { type: "add_node", targetId: id, label: `${selectedNode.label} Copy` } },
    );
  }

  function updateSelectedNode(message: string, mutate: (node: GraphNode) => GraphNode) {
    if (!selectedNode) return;
    const mutated = mutate(selectedNode);
    commitDocument(
      withDocumentUpdate(document, {
        nodes: document.nodes.map((node) => (node.id === selectedNode.id ? mutated : node)),
      }),
      message,
      { selectId: selectedNode.id, op: inspectorOp(selectedNode, mutated) },
    );
  }

  function addMember(kind: "attribute" | "operation") {
    if (!selectedNode) {
      setHint(`Select an element to add ${kind === "attribute" ? "an attribute" : "an operation"}.`);
      return;
    }
    const attributes = selectedNode.uml?.attributes ?? [];
    const operations = selectedNode.uml?.operations ?? [];
    if (kind === "attribute") {
      const next = [...attributes, `+ field${attributes.length + 1} : String`];
      updateSelectedNode(`Added attribute to ${selectedNode.label}`, (node) => ({
        ...node,
        uml: { ...node.uml, attributes: next },
        members: [...next, ...operations],
      }));
    } else {
      const next = [...operations, `+ operation${operations.length + 1}() : void`];
      updateSelectedNode(`Added operation to ${selectedNode.label}`, (node) => ({
        ...node,
        uml: { ...node.uml, operations: next },
        members: [...attributes, ...next],
      }));
    }
  }

  function focusSelected() {
    if (!selectedNode) {
      setHint("Select an element to frame it.");
      return;
    }
    setFocusId(selectedNode.id);
    setHint(`Framed ${selectedNode.label}`);
  }

  function recenter() {
    setFocusId(null);
    setSelectedId(document.nodes[0]?.id ?? null);
    setHint("Framed the whole model.");
  }

  function undo() {
    const previous = history.at(-1);
    if (!previous) {
      setHint("Nothing to undo.");
      return;
    }
    setRedoStack((items) => [document, ...items].slice(0, 50));
    setHistory((items) => items.slice(0, -1));
    setDocument(previous);
    documentRef.current = previous;
    retainSelection(previous);
    setHint("Undo applied.");
    scheduleAutosave();
  }

  function redo() {
    const next = redoStack[0];
    if (!next) {
      setHint("Nothing to redo.");
      return;
    }
    setHistory((items) => [...items, document].slice(-50));
    setRedoStack((items) => items.slice(1));
    setDocument(next);
    documentRef.current = next;
    retainSelection(next);
    setHint("Redo applied.");
    scheduleAutosave();
  }

  function readCameraPoseIntoForm() {
    const pose = sceneHandleRef.current?.getCameraPose();
    if (!pose) {
      setHint("Camera is not ready yet.");
      return;
    }
    const fmt = (value: number) => (Math.round(value * 10) / 10).toString();
    setCameraForm({
      yaw: fmt(pose.yaw),
      pitch: fmt(pose.pitch),
      roll: fmt(pose.roll),
      x: fmt(pose.pivot.x),
      y: fmt(pose.pivot.y),
      z: fmt(pose.pivot.z),
      distance: fmt(pose.distance),
    });
  }

  function applyCameraForm() {
    if (!cameraForm || !sceneHandleRef.current) return;
    const num = (value: string, fallback = 0) => {
      const parsed = Number.parseFloat(value);
      return Number.isFinite(parsed) ? parsed : fallback;
    };
    sceneHandleRef.current.setCameraPose({
      yaw: num(cameraForm.yaw),
      pitch: num(cameraForm.pitch),
      roll: num(cameraForm.roll),
      pivot: { x: num(cameraForm.x), y: num(cameraForm.y), z: num(cameraForm.z) },
      distance: num(cameraForm.distance, 18),
    });
    setHint("Applied camera pose.");
  }

  function hintForMode(next: ToolMode, sourceId: string | null, relationship: UmlRelationship, kind: ElementKindKey | null) {
    if (next === "connect") {
      return sourceId
        ? `Connect (${relationship}): source ${nodeLabel(sourceId)} — pick a target`
        : `Connect (${relationship}): pick a source node`;
    }
    if (next === "place") {
      const label = kind ? ELEMENT_KINDS.find((entry) => entry.key === kind)?.label ?? kind : null;
      return label
        ? `Place: click in the scene to add a ${label} (or drag the chip in)`
        : "Place: drag an element kind from the palette into the scene";
    }
    return SELECT_HINT;
  }

  /** IA.md law #4 — a mode change echoes in the segmented control, the status chip and
   * the hint line at once. Those three read `mode` / `hint`, so one setter covers all. */
  function setMode(next: ToolMode) {
    setModeState(next);
    setConnectSourceId(null);
    if (next !== "place") {
      setArmedKind(null);
      pendingKindRef.current = null;
    }
    setHint(hintForMode(next, null, relationshipType, next === "place" ? armedKind : null));
  }

  function nodeLabel(nodeId: string) {
    return document.nodes.find((node) => node.id === nodeId)?.label ?? nodeId;
  }

  function createRelationship(sourceId: string, targetId: string) {
    const source = document.nodes.find((node) => node.id === sourceId);
    const target = document.nodes.find((node) => node.id === targetId);
    if (!source || !target) {
      setConnectSourceId(null);
      setHint("Connect: source or target no longer exists. Pick a source node.");
      return;
    }
    const duplicate = document.edges.some(
      (edge) => edge.sourceId === sourceId && edge.targetId === targetId && edge.uml?.relationship === relationshipType,
    );
    if (duplicate) {
      setConnectSourceId(null);
      setHint(`Connect: ${relationshipType} from ${source.label} to ${target.label} already exists.`);
      return;
    }
    const usedIds = new Set(document.edges.map((edge) => edge.id));
    const baseId = `${relationshipType}-${sourceId}-${targetId}`;
    let id = baseId;
    let suffix = 2;
    while (usedIds.has(id)) {
      id = `${baseId}-${suffix}`;
      suffix += 1;
    }
    const edge: GraphEdge = {
      id,
      sourceId,
      targetId,
      kind: relationshipEdgeKind[relationshipType],
      label: relationshipType,
      uml: { relationship: relationshipType, ...relationshipStyle[relationshipType] },
    };
    setConnectSourceId(null);
    commitDocument(
      withDocumentUpdate(document, { edges: [...document.edges, edge] }),
      `Connected ${source.label} → ${target.label} (${relationshipType}) — click the next source`,
      { selectId: targetId, op: { type: "connect", targetId: id, label: relationshipType } },
    );
  }

  function handleSceneSelect(nodeId: string | null) {
    sceneHitAtRef.current = Date.now();
    if (mode !== "connect") {
      if (mode === "place" && armedKind) return;
      setSelectedId(nodeId);
      if (nodeId) setHint(`Selected ${nodeLabel(nodeId)}`);
      return;
    }
    if (!nodeId) {
      if (connectSourceId) {
        setConnectSourceId(null);
        setHint(`Connect (${relationshipType}): pick a source node`);
      }
      return;
    }
    if (!connectSourceId) {
      setConnectSourceId(nodeId);
      setSelectedId(nodeId);
      setHint(`Connect (${relationshipType}): source ${nodeLabel(nodeId)} — pick a target`);
      return;
    }
    if (nodeId === connectSourceId) {
      setConnectSourceId(null);
      setHint("Connect: source cleared. Pick a source node.");
      return;
    }
    createRelationship(connectSourceId, nodeId);
  }

  // Stable identity so the three.js scene effect (which lists onSelect in its deps)
  // does not tear down and rebuild on every workspace render.
  const sceneSelectRef = useRef(handleSceneSelect);
  sceneSelectRef.current = handleSceneSelect;
  const stableSceneSelect = useCallback((nodeId: string) => sceneSelectRef.current(nodeId), []);
  const sceneStatusRef = useRef(setHint);
  sceneStatusRef.current = setHint;
  const stableSceneStatus = useCallback((message: string) => sceneStatusRef.current(message), []);

  function exportAs(format: "json" | "trdyaml" | "plantuml" | "mermaid" | "dot" | SkeletonLanguage) {
    if (format === "json") {
      downloadText(filenameFor(document, "trd.json"), JSON.stringify(document, null, 2), "application/json");
      setHint(`Saved ${document.title} as TRD JSON.`);
      return;
    }
    if (format === "trdyaml") {
      downloadText(filenameFor(document, "trd-yaml"), exportTrdYaml(document), "text/yaml");
      setHint(`Saved ${document.title} as TRD YAML.`);
      return;
    }
    if (format === "plantuml") {
      downloadText(filenameFor(document, "puml"), exportPlantUml(document), "text/plain");
      setHint("Exported PlantUML.");
      return;
    }
    if (format === "mermaid") {
      downloadText(filenameFor(document, "mmd"), exportMermaid(document), "text/plain");
      setHint("Exported Mermaid class diagram.");
      return;
    }
    if (format === "dot") {
      downloadText(filenameFor(document, "dot"), exportDot(document), "text/vnd.graphviz");
      setHint("Exported DOT graph.");
      return;
    }
    const entry = skeletonLanguages.find((item) => item.value === format) ?? skeletonLanguages[0];
    downloadText(filenameFor(document, entry.extension), exportCodeSkeleton(document, entry.value), "text/plain");
    setHint(`Exported ${entry.label} code skeleton.`);
  }

  function openOutlineSearch() {
    setFocusMode(false);
    setBrowserCollapsed(false);
    setBrowserTab("outline");
    window.setTimeout(() => outlineFilterRef.current?.focus(), 0);
  }

  async function openDocumentById(id: string) {
    setBusy(true);
    try {
      const opened = await store.load(id);
      bindDocument(
        opened,
        `Opened ${opened.title}`,
        store.kind === "cloud" ? { id: opened.id, version: opened.version } : null,
      );
    } catch (error) {
      setHint(error instanceof Error ? error.message : `Could not open ${id}.`);
    } finally {
      setBusy(false);
    }
  }

  /** Explicit Save (⌘S). Cloud sessions publish a full document — creating the row on
   * first save, then optimistic-locked on the version the editor loaded. Browser-local
   * sessions keep the demo's behaviour and write a file. */
  async function saveNow() {
    if (store.kind !== "cloud") {
      exportAs("json");
      return;
    }

    cancelAutosave();
    pendingOpsRef.current = [];
    const target = remoteRef.current;
    setBusy(true);
    setSaveState("saving");
    try {
      const saved = target
        ? await store.save(documentRef.current, { expectedVersion: target.version })
        : await store.create(documentRef.current);
      if (!target) {
        // The server assigns the document's id and a unique slug on create; adopt them so
        // subsequent autosaves address the row that was just written.
        setDocument(saved);
        documentRef.current = saved;
        pushRecent(saved);
      }
      setRemote({ id: saved.id, version: saved.version });
      remoteRef.current = { id: saved.id, version: saved.version };
      setSaveState("idle");
      setHint(`Saved ${saved.title} · v${saved.version}`);
      refreshDocuments();
    } catch (error) {
      if (error instanceof DocVersionConflictError && target) {
        await reloadAfterConflict(target.id, error.currentVersion);
        return;
      }
      setSaveState("error");
      setHint(error instanceof Error ? `Save failed: ${error.message}` : "Save failed.");
    } finally {
      setBusy(false);
    }
  }

  function armKind(key: ElementKindKey) {
    setArmedKind(key);
    setModeState("place");
    setConnectSourceId(null);
    setHint(hintForMode("place", null, relationshipType, key));
  }

  function armNodeKind(nodeKind: NodeKind) {
    const chip = ELEMENT_KINDS.find((entry) => entry.nodeKind === nodeKind);
    if (chip) {
      armKind(chip.key);
      return;
    }
    // Kind browser entries with no chip still arm Place mode; the hint carries the label.
    setArmedKind(null);
    setModeState("place");
    setHint(`Place: click in the scene to add a ${nodeKind}`);
    pendingKindRef.current = nodeKind;
  }

  const pendingKindRef = useRef<NodeKind | null>(null);

  function armedNodeKind(): NodeKind | null {
    if (armedKind) return ELEMENT_KINDS.find((entry) => entry.key === armedKind)?.nodeKind ?? null;
    return pendingKindRef.current;
  }

  // ---------------------------------------------------------------- command wiring
  const handlers = new Map<TrdCommandId, () => void>();
  const register = (id: TrdCommandId, run: () => void) => handlers.set(id, run);

  register("file.new", () => replaceDocument(createEmptyDocument(), "Created a new empty 3D UML workspace."));
  register("file.open", () => graphFileInputRef.current?.click());
  register("file.save", () => void saveNow());
  register("file.saveAs", () => exportAs("json"));
  register("file.import.plantuml", () => plantUmlInputRef.current?.click());
  register("file.import.sourceFolder", () => codeInputRef.current?.click());
  register("file.export.trdyaml", () => exportAs("trdyaml"));
  register("file.export.json", () => exportAs("json"));
  register("file.export.plantuml", () => exportAs("plantuml"));
  register("file.export.mermaid", () => exportAs("mermaid"));
  register("file.export.dot", () => exportAs("dot"));
  for (const language of skeletonLanguages) {
    register(`file.export.code.${language.value}`, () => exportAs(language.value));
  }
  register("file.closeDiagram", () => replaceDocument(createEmptyDocument(), "Closed the diagram."));
  recents.forEach((entry, index) => {
    register(`file.openRecent.${index}`, () => replaceDocument(entry.document, `Reopened ${entry.title}`));
  });

  register("edit.undo", undo);
  register("edit.redo", redo);
  register("edit.copy", copySelected);
  register("edit.paste", pasteNode);
  register("edit.cut", () => {
    copySelected();
    deleteSelected();
  });
  register("edit.duplicate", duplicateSelected);
  register("edit.delete.removeEverywhere", deleteSelected);
  register("edit.find", openOutlineSearch);
  register("edit.rename", () => {
    if (!selectedNode) {
      setHint("Select an element to rename.");
      return;
    }
    setInspectorCollapsed(false);
    setFocusMode(false);
    window.setTimeout(() => inspectorNameRef.current?.select(), 0);
  });

  for (const entry of ELEMENT_KINDS) {
    if (!entry.nodeKind) continue;
    const nodeKind = entry.nodeKind;
    register(`model.add.${entry.key}`, () => addNode(nodeKind));
  }
  register("model.add.more", () => setKindBrowserOpen(true));
  register("model.members.addAttribute", () => addMember("attribute"));
  register("model.members.addOperation", () => addMember("operation"));
  register("model.connect", () => setMode(mode === "connect" ? "select" : "connect"));
  for (const kind of UML_RELATIONSHIPS) {
    register(`model.relationship.${kind}`, () => {
      setRelationshipType(kind);
      if (mode === "connect") setHint(hintForMode("connect", connectSourceId, kind, null));
      else setHint(`Relationship type set to ${kind}.`);
    });
  }

  register("go.commandPalette", () => setPaletteOpen(true));
  register("go.jumpToElement", openOutlineSearch);
  register("go.frameSelected", focusSelected);
  register("go.frameAll", recenter);
  register("go.trace.start", () => {
    if (!selectedNode) {
      setHint("Select an element to start a trace.");
      return;
    }
    setTraceEnabled(true);
    setHint(`Tracing neighbours of ${selectedNode.label}.`);
  });
  register("go.trace.close", () => {
    setTraceEnabled(false);
    setHint("Trace closed.");
  });

  register("view.modelBrowser", () => setBrowserCollapsed((current) => !current));
  register("view.inspector", () => setInspectorCollapsed((current) => !current));
  register("view.outline", () => {
    setBrowserCollapsed(false);
    setBrowserTab((current) => (current === "outline" ? "files" : "outline"));
  });
  register("view.elementPalette", () => setPaletteDockCollapsed((current) => !current));
  register("view.statusBar", () => setStatusVisible((current) => !current));
  register("view.camera.controls", () => (cameraForm ? setCameraForm(null) : readCameraPoseIntoForm()));
  register("view.camera.overview", recenter);
  register("view.camera.focus", focusSelected);
  register("view.camera.reset", () => {
    sceneHandleRef.current?.resetCamera();
    setHint("Camera reset to framed model.");
  });
  register("view.appearance.traceNeighbors", () => {
    setTraceEnabled((current) => {
      setHint(current ? "Trace neighbours off." : "Trace neighbours on.");
      return !current;
    });
  });
  register("view.focusMode", () => setFocusMode((current) => !current));
  register("view.fullScreen", () => {
    const root = window.document.documentElement;
    if (window.document.fullscreenElement) void window.document.exitFullscreen();
    else void root.requestFullscreen?.();
  });

  register("code.generateForSelection", () => exportAs("csharp"));

  register("help.keyboardShortcuts", () =>
    setHint("⌘K palette · V/C/P modes · ⌘Z undo · ⌘S save · ⌘F find · F frame · Home frame all · ⌃⌘F focus mode"),
  );
  register("help.sample.unityParity", () => replaceDocument(demoDocument, "Loaded the Unity parity example model."));

  function runCommand(id: TrdCommandId) {
    const run = handlers.get(id);
    if (!run) return;
    setOpenMenu(null);
    setContextMenu(null);
    setCommandMru((current) => {
      const next = [id, ...current.filter((entry) => entry !== id)].slice(0, COMMAND_MRU_LIMIT);
      try {
        window.localStorage.setItem(commandMruKey, JSON.stringify(next));
      } catch {
        /* non-critical */
      }
      return next;
    });
    run();
  }

  const runCommandRef = useRef(runCommand);
  runCommandRef.current = runCommand;

  // ---------------------------------------------------------------- palette catalogue
  const paletteCommands = useMemo<PaletteCommand[]>(() => {
    const rank = new Map(commandMru.map((id, index) => [id, index]));
    return MENU_COMMANDS.filter((entry) => handlers.has(entry.command))
      .map((entry) => ({ id: entry.command, category: entry.category, label: entry.label, kbd: entry.kbd }))
      .sort((a, b) => (rank.get(a.id) ?? Number.MAX_SAFE_INTEGER) - (rank.get(b.id) ?? Number.MAX_SAFE_INTEGER));
    // `handlers` is rebuilt every render but always carries the same key set, so keying
    // this on the MRU alone is correct and keeps the list identity stable.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [commandMru, recents.length]);

  // ---------------------------------------------------------------- dynamic menu slots
  const dynamicItems: Record<"recents" | "windows", MenuEntry[]> = {
    recents: recents.map((entry, index) => ({
      label: entry.slug,
      command: `file.openRecent.${index}` as TrdCommandId,
    })),
    windows: [{ label: document.slug, check: "window.current" }],
  };

  const checks: Record<string, boolean> = {
    "view.modelBrowser": !browserCollapsed,
    "view.inspector": !inspectorCollapsed,
    "view.outline": browserTab === "outline",
    "view.elementPalette": !paletteDockCollapsed,
    "view.statusBar": statusVisible,
    "view.focusMode": focusMode,
    "appearance.traceNeighbors": traceEnabled,
    "theme.dark": true,
    "layout.keepHandPlacements": true,
    "window.current": true,
  };
  for (const kind of UML_RELATIONSHIPS) checks[`relationship.${kind}`] = relationshipType === kind;

  // ---------------------------------------------------------------- keyboard
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      const target = event.target;
      const typing =
        target instanceof HTMLInputElement ||
        target instanceof HTMLTextAreaElement ||
        target instanceof HTMLSelectElement;
      const meta = event.metaKey || event.ctrlKey;
      const key = event.key.toLowerCase();

      if (meta && key === "k") {
        event.preventDefault();
        if (event.shiftKey) setKindBrowserOpen(true);
        else setPaletteOpen(true);
        return;
      }

      // IA.md Escape priority: palette → menu → pending connect source → revert to Select.
      if (event.key === "Escape") {
        if (paletteOpen) {
          setPaletteOpen(false);
          return;
        }
        if (kindBrowserOpen) {
          setKindBrowserOpen(false);
          return;
        }
        if (openMenu) {
          setOpenMenu(null);
          return;
        }
        if (contextMenu) {
          setContextMenu(null);
          return;
        }
        if (connectSourceId) {
          setConnectSourceId(null);
          setHint(`Connect (${relationshipType}): pick a source node`);
          return;
        }
        if (mode !== "select") setMode("select");
        return;
      }

      if (paletteOpen) return;

      if (meta) {
        // Leave the native clipboard / select-all bindings alone while a field has focus.
        if (typing && ["x", "c", "v", "a"].includes(key)) return;
        if (event.altKey) {
          if (key === "1") {
            event.preventDefault();
            runCommandRef.current("view.modelBrowser");
          }
          if (key === "2") {
            event.preventDefault();
            runCommandRef.current("view.inspector");
          }
          if (key === "3") {
            event.preventDefault();
            runCommandRef.current("view.outline");
          }
          if (key === "4") {
            event.preventDefault();
            runCommandRef.current("view.elementPalette");
          }
          return;
        }
        if (event.ctrlKey && event.metaKey && key === "f") {
          event.preventDefault();
          runCommandRef.current("view.focusMode");
          return;
        }
        if (event.shiftKey) {
          if (key === "c") {
            event.preventDefault();
            runCommandRef.current("view.camera.controls");
          }
          if (key === "z") {
            event.preventDefault();
            runCommandRef.current("edit.redo");
          }
          if (key === "s") {
            event.preventDefault();
            runCommandRef.current("file.saveAs");
          }
          return;
        }
        if (key === "n") {
          event.preventDefault();
          runCommandRef.current("file.new");
        } else if (key === "o") {
          event.preventDefault();
          runCommandRef.current("file.open");
        } else if (key === "s") {
          event.preventDefault();
          runCommandRef.current("file.save");
        } else if (key === "z") {
          event.preventDefault();
          runCommandRef.current("edit.undo");
        } else if (key === "x") {
          event.preventDefault();
          runCommandRef.current("edit.cut");
        } else if (key === "c") {
          event.preventDefault();
          runCommandRef.current("edit.copy");
        } else if (key === "v") {
          event.preventDefault();
          runCommandRef.current("edit.paste");
        } else if (key === "d") {
          event.preventDefault();
          runCommandRef.current("edit.duplicate");
        } else if (key === "f") {
          event.preventDefault();
          runCommandRef.current("edit.find");
        } else if (key === "g") {
          event.preventDefault();
          runCommandRef.current("code.generateForSelection");
        } else if (key === "j") {
          event.preventDefault();
          runCommandRef.current("go.jumpToElement");
        } else if (key === "t") {
          event.preventDefault();
          runCommandRef.current("go.trace.start");
        } else if (key === "w") {
          event.preventDefault();
          runCommandRef.current("file.closeDiagram");
        } else if (key === "/") {
          event.preventDefault();
          runCommandRef.current("help.keyboardShortcuts");
        }
        return;
      }

      // Everything below is a bare key: never steal it from a focused field.
      if (typing) return;

      if (event.altKey && key === "a") {
        event.preventDefault();
        runCommandRef.current("model.members.addAttribute");
        return;
      }
      if (event.altKey && key === "o") {
        event.preventDefault();
        runCommandRef.current("model.members.addOperation");
        return;
      }
      if (event.altKey && event.key === "Backspace") {
        event.preventDefault();
        runCommandRef.current("edit.delete.removeEverywhere");
        return;
      }
      if (event.key === "Backspace") {
        setHint("Unlink needs multi-diagram support — use ⌥⌫ to remove from the model.");
        return;
      }
      if (event.key === "Delete") {
        runCommandRef.current("edit.delete.removeEverywhere");
        return;
      }
      if (key === "v") setMode("select");
      else if (key === "c") setMode("connect");
      else if (key === "p") setMode("place");
      else if (key === "f") focusSelected();
      else if (event.key === "Home") recenter();
      else if (event.key === "ArrowRight" && document.nodes.length) {
        setSelectedId(nextNode(document.nodes, selectedId ?? "", 1));
      } else if (event.key === "ArrowLeft" && document.nodes.length) {
        setSelectedId(nextNode(document.nodes, selectedId ?? "", -1));
      }
    }

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  });

  // ---------------------------------------------------------------- file inputs
  async function handleGraphFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = "";
    if (!file) return;
    try {
      const text = await file.text();
      const restored = looksLikeTrdYaml(text, file.name)
        ? importTrdYaml(text, file.name)
        : readGraphDocumentJson(text);
      replaceDocument(restored, `Opened ${file.name}`);
    } catch (error) {
      setHint(error instanceof Error ? error.message : `Could not open ${file.name}.`);
    }
  }

  async function handlePlantUmlFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.currentTarget.files?.[0];
    event.currentTarget.value = "";
    if (!file) return;
    try {
      replaceDocument(importPlantUml(await file.text(), file.name), `Imported PlantUML from ${file.name}`);
    } catch (error) {
      setHint(error instanceof Error ? error.message : `Could not import ${file.name}.`);
    }
  }

  async function handleCodeFiles(event: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.currentTarget.files ?? []);
    event.currentTarget.value = "";
    if (!files.length) return;
    try {
      const payloads = await Promise.all(files.map(async (file) => ({ name: file.name, text: await file.text() })));
      replaceDocument(importCodeFiles(payloads), `Imported ${files.length} source file${files.length === 1 ? "" : "s"}.`);
    } catch (error) {
      setHint(error instanceof Error ? error.message : "Could not import code files.");
    }
  }

  // ---------------------------------------------------------------- viewport interaction
  function handleCanvasDragOver(event: React.DragEvent<HTMLElement>) {
    if (!event.dataTransfer.types.includes(TRD_KIND_DRAG_TYPE)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
  }

  function handleCanvasDrop(event: React.DragEvent<HTMLElement>) {
    const key = event.dataTransfer.getData(TRD_KIND_DRAG_TYPE);
    if (!key) return;
    event.preventDefault();
    // Single resolution point for both entry gestures: drag carries an ElementKindKey,
    // exactly as click-to-arm does, and NodeKind is derived here.
    const kind = ELEMENT_KINDS.find((entry) => entry.key === key)?.nodeKind;
    if (!kind) return;
    const at = sceneHandleRef.current?.dropPointAt(event.clientX, event.clientY);
    addNode(kind, at ?? undefined);
  }

  function handleViewportClick(event: MouseEvent<HTMLElement>) {
    setContextMenu(null);
    if (mode !== "place") return;
    // Overlays live inside the viewport box; a click on one is never a placement.
    const target = event.target;
    if (
      target instanceof Element &&
      target.closest(".trd-popover, .cd-palette-scrim, .trd-viewport-empty, .trd-hint")
    ) {
      return;
    }
    const kind = armedNodeKind();
    if (!kind) return;
    // The scene's own canvas listener already ran if a node was hit.
    if (Date.now() - sceneHitAtRef.current < 60) return;
    const at = sceneHandleRef.current?.dropPointAt(event.clientX, event.clientY);
    addNode(kind, at ?? undefined);
  }

  function openCanvasContextMenu(event: MouseEvent<HTMLElement>) {
    event.preventDefault();
    setContextMenu({ x: event.clientX, y: event.clientY, nodeId: selectedId });
  }

  // ---------------------------------------------------------------- derived chrome data
  const crumbs = selectedNode
    ? [
        ...(selectedNode.packageName ? [{ label: selectedNode.packageName }] : []),
        { label: selectedNode.label, onClick: focusSelected },
      ]
    : [];
  const breadcrumbText = [document.slug, selectedNode?.label].filter(Boolean).join(" ▸ ");
  const selectionSummary = selectedNode ? `${selectedNode.label} selected` : "No selection";
  // Browser-local models keep reporting the editor's own version counter; cloud models
  // report the store's, which is the only number that survives a reload.
  const savedLabel =
    store.kind !== "cloud"
      ? `autosaved · v${document.version}`
      : saveState === "saving"
        ? "saving…"
        : saveState === "error"
          ? "not saved · draft kept locally"
          : remote
            ? `autosaved · v${remote.version}`
            : "unpublished · ⌘S to save";
  const kindBrowserResults = KIND_BROWSER_ENTRIES.filter(
    (entry) => !kindBrowserFilter || entry.label.toLowerCase().includes(kindBrowserFilter.trim().toLowerCase()),
  );

  const shellClass = [
    "trd-shell",
    focusMode ? "is-focus-mode" : "",
    statusVisible ? "" : "trd-shell--no-status",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={shellClass} onClick={() => setContextMenu(null)}>
      <input
        ref={graphFileInputRef}
        type="file"
        accept=".json,.trd,.trd.json,.trd-yaml,.trd.yaml,.yaml,.yml,application/json"
        hidden
        onChange={handleGraphFile}
      />
      <input ref={plantUmlInputRef} type="file" accept=".puml,.plantuml,.txt,text/plain" hidden onChange={handlePlantUmlFile} />
      <input
        ref={codeInputRef}
        type="file"
        accept=".cs,.ts,.tsx,.js,.jsx,.java,.kt,.swift,.py,.go,.rs,.cpp,.h,.hpp,.txt"
        multiple
        hidden
        onChange={handleCodeFiles}
      />

      <MenuBar
        openMenu={openMenu}
        onOpenMenu={setOpenMenu}
        isEnabled={(command) => handlers.has(command)}
        onRun={runCommand}
        checks={checks}
        dynamicItems={dynamicItems}
        appTitle={`TheRobotDrafts — ${document.slug}`}
      />

      <ContextToolbar
        browserCollapsed={browserCollapsed}
        onToggleBrowser={() => runCommand("view.modelBrowser")}
        modelName={document.slug}
        crumbs={crumbs}
        mode={mode}
        onModeChange={setMode}
        relationshipType={relationshipType}
        onRelationshipChange={(value) => runCommand(`model.relationship.${value}`)}
        onCameraControls={() => runCommand("view.camera.controls")}
        onStartTrace={() => runCommand("go.trace.start")}
        onCommandPalette={() => runCommand("go.commandPalette")}
        traceActive={traceEnabled}
      />

      <div className="trd-body">
        <IconRail
          browserOpen={!browserCollapsed}
          onToggleBrowser={() => runCommand("view.modelBrowser")}
          onSearch={() => runCommand("edit.find")}
          onAddElement={() => runCommand("model.add.more")}
          onImportExport={() => setOpenMenu("File")}
        />

        <BrowserDock
          collapsed={browserCollapsed}
          tab={browserTab}
          onTabChange={setBrowserTab}
          document={document}
          selectedId={selectedId}
          onSelectNode={(id) => {
            setSelectedId(id);
            setHint(`Selected ${nodeLabel(id)}`);
          }}
          documents={documents}
          onOpenDocument={openDocumentById}
          onFrameNode={(id) => {
            setSelectedId(id);
            setFocusId(id);
            setHint(`Framed ${nodeLabel(id)}`);
          }}
          recents={recents}
          onOpenRecent={(index) => runCommand(`file.openRecent.${index}`)}
          query={query}
          onQueryChange={setQuery}
          matchingNodes={matchingNodes}
          filterRef={outlineFilterRef}
        />

        <PaletteDock
          collapsed={paletteDockCollapsed}
          armedKey={armedKind}
          onArm={armKind}
          onOpenKindBrowser={() => runCommand("model.add.more")}
        />

        <section
          className="trd-viewport"
          aria-label="Interactive 3D UML renderer"
          onContextMenu={openCanvasContextMenu}
          onDragOver={handleCanvasDragOver}
          onDrop={handleCanvasDrop}
          onClick={handleViewportClick}
        >
          <TrdThreeScene
            document={document}
            selectedId={selectedNode?.id}
            focusId={focusId}
            tracedEdgeIds={tracedEdgeIds}
            onSelect={stableSceneSelect}
            onStatus={stableSceneStatus}
            handleRef={sceneHandleRef}
          />

          {!document.nodes.length ? (
            <div className="trd-viewport-empty">
              <strong>Empty 3D UML workspace</strong>
              <div>
                <button type="button" onClick={() => runCommand("file.open")}>
                  Open TRD model
                </button>
                <button type="button" onClick={() => runCommand("file.import.sourceFolder")}>
                  Import code
                </button>
                <button type="button" onClick={() => runCommand("help.sample.unityParity")}>
                  Load example
                </button>
              </div>
            </div>
          ) : null}

          {cameraForm ? (
            <div
              className="trd-popover trd-camera-form"
              style={{ right: 14, top: 14 }}
              role="dialog"
              aria-label="Camera pose form"
              onClick={(event) => event.stopPropagation()}
            >
              {(
                [
                  ["yaw", "Yaw"],
                  ["pitch", "Pitch"],
                  ["roll", "Roll"],
                  ["x", "Pivot X"],
                  ["y", "Pivot Y"],
                  ["z", "Pivot Z"],
                  ["distance", "Distance"],
                ] as const
              ).map(([field, label]) => (
                <label key={field}>
                  <span>{label}</span>
                  <input
                    type="number"
                    step="1"
                    value={cameraForm[field]}
                    onChange={(event) => setCameraForm({ ...cameraForm, [field]: event.target.value })}
                  />
                </label>
              ))}
              <button type="button" onClick={applyCameraForm}>
                Apply
              </button>
              <button type="button" onClick={() => runCommand("view.camera.reset")}>
                Reset
              </button>
              <button type="button" onClick={() => setCameraForm(null)}>
                Close
              </button>
            </div>
          ) : null}

          {kindBrowserOpen ? (
            <div
              className="trd-popover trd-kind-browser"
              role="dialog"
              aria-label="Kind browser"
              onClick={(event) => event.stopPropagation()}
            >
              <input
                className="trd-filter"
                autoFocus
                placeholder="Filter kinds…"
                aria-label="Filter kinds"
                value={kindBrowserFilter}
                onChange={(event) => setKindBrowserFilter(event.target.value)}
              />
              {kindBrowserResults.map((entry) => (
                <button
                  key={`${entry.family}:${entry.label}`}
                  type="button"
                  disabled={!entry.nodeKind}
                  title={entry.nodeKind ? `Arm Place mode with ${entry.label}` : "No document kind for this element yet"}
                  onClick={() => {
                    if (!entry.nodeKind) return;
                    armNodeKind(entry.nodeKind);
                    setKindBrowserOpen(false);
                  }}
                >
                  <span>{entry.label}</span>
                  <span className="trd-kbd">{entry.family}</span>
                </button>
              ))}
            </div>
          ) : null}

          <div className="trd-hint" aria-live="polite">
            {hint}
          </div>

          <CommandPalette
            open={paletteOpen}
            commands={paletteCommands}
            onRun={(id) => runCommand(id as TrdCommandId)}
            onClose={() => setPaletteOpen(false)}
          />
        </section>

        <Inspector
          collapsed={inspectorCollapsed}
          node={selectedNode}
          onUpdate={updateSelectedNode}
          nameRef={inspectorNameRef}
        />
      </div>

      <LiveStatusStrip
        mode={mode}
        breadcrumb={breadcrumbText}
        selection={selectionSummary}
        zLayer={document.view?.activeLayer ?? 0}
        // Empty label collapses the segment via status-strip.css's `:empty` rule —
        // this slot is for background work, not for model statistics.
        taskLabel={busy ? "loading model" : ""}
        taskActive={busy}
        savedLabel={savedLabel}
        sceneHandleRef={sceneHandleRef}
      />

      {contextMenu ? (
        <div
          className="trd-popover"
          style={{ left: contextMenu.x, top: contextMenu.y, position: "fixed" }}
          role="menu"
          onClick={(event) => event.stopPropagation()}
        >
          <button type="button" role="menuitem" onClick={() => runCommand("model.add.class")}>
            Add Class
          </button>
          <button type="button" role="menuitem" onClick={() => runCommand("model.add.interface")}>
            Add Interface
          </button>
          <button type="button" role="menuitem" onClick={() => runCommand("file.import.sourceFolder")}>
            Import Code…
          </button>
          <button type="button" role="menuitem" onClick={() => runCommand("file.import.plantuml")}>
            Import PlantUML…
          </button>
          <button type="button" role="menuitem" onClick={() => runCommand("file.export.plantuml")}>
            Export PlantUML
          </button>
          <button type="button" role="menuitem" onClick={() => runCommand("code.generateForSelection")}>
            Export Code Skeleton
          </button>
          <button
            type="button"
            role="menuitem"
            disabled={!contextMenu.nodeId}
            onClick={() => runCommand("edit.delete.removeEverywhere")}
          >
            Remove from Model
          </button>
        </div>
      ) : null}
    </div>
  );
}
