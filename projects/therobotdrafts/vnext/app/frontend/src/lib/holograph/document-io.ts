import type { EdgeKind, GraphDocument, GraphEdge, GraphNode, NodeKind } from "./types";

export interface TextFilePayload {
  name: string;
  text: string;
}

const nodeKinds = new Set<NodeKind>(["system", "package", "service", "class", "interface", "function", "database", "agent"]);
const edgeKinds = new Set<EdgeKind>(["contains", "calls", "depends_on", "publishes", "stores", "patches"]);

function slugify(value: string) {
  return (
    value
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 72) || "untitled"
  );
}

function idFor(prefix: string, value: string, used: Set<string>) {
  const base = `${prefix}-${slugify(value)}`;
  let candidate = base;
  let index = 2;
  while (used.has(candidate)) {
    candidate = `${base}-${index}`;
    index += 1;
  }
  used.add(candidate);
  return candidate;
}

function metricsFor(label: string): GraphNode["metrics"] {
  const seed = Array.from(label).reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return {
    complexity: 18 + (seed % 43),
    churn: 8 + (seed % 29),
    risk: 10 + (seed % 38),
  };
}

export function createEmptyDocument(now = new Date()): GraphDocument {
  const updatedAt = now.toISOString();
  return {
    id: `trd-${Date.now().toString(36)}`,
    slug: "untitled-3d-uml-model",
    title: "Untitled 3D UML model",
    version: 1,
    updatedAt,
    summary: "Empty The Robot Draft 3D UML workspace.",
    modelKind: "uml",
    view: {
      projection: "trd-3d-uml",
      activeLayer: 0,
      camera: {
        target: { x: 0, y: 0, z: 0 },
        yaw: 35,
        pitch: 22,
        distance: 18,
      },
    },
    nodes: [],
    edges: [],
  };
}

export function isGraphDocument(value: unknown): value is GraphDocument {
  if (!value || typeof value !== "object") return false;
  const candidate = value as Partial<GraphDocument>;
  return (
    typeof candidate.id === "string" &&
    typeof candidate.slug === "string" &&
    typeof candidate.title === "string" &&
    typeof candidate.version === "number" &&
    Array.isArray(candidate.nodes) &&
    Array.isArray(candidate.edges)
  );
}

export function normalizeGraphDocument(input: GraphDocument): GraphDocument {
  const usedNodeIds = new Set<string>();
  const nodes = input.nodes
    .filter((node) => nodeKinds.has(node.kind))
    .map((node) => {
      const id = node.id && !usedNodeIds.has(node.id) ? node.id : idFor("node", node.label, usedNodeIds);
      usedNodeIds.add(id);
      return {
        ...node,
        id,
        description: node.description || `${node.label} UML element.`,
        metrics: node.metrics ?? metricsFor(node.label),
      };
    });

  const nodeIds = new Set(nodes.map((node) => node.id));
  const edges = input.edges
    .filter((edge) => nodeIds.has(edge.sourceId) && nodeIds.has(edge.targetId) && edgeKinds.has(edge.kind))
    .map((edge, index) => ({
      ...edge,
      id: edge.id || `edge-${index + 1}`,
      label: edge.label || edge.kind,
    }));

  return {
    ...input,
    modelKind: input.modelKind ?? "uml",
    view: input.view ?? { projection: "trd-3d-uml", activeLayer: 0 },
    updatedAt: input.updatedAt || new Date().toISOString(),
    nodes,
    edges,
  };
}

export function readGraphDocumentJson(text: string): GraphDocument {
  const parsed = JSON.parse(text) as unknown;
  if (!isGraphDocument(parsed)) throw new Error("The selected JSON is not a TRD GraphDocument.");
  return normalizeGraphDocument(parsed);
}

export function importPlantUml(text: string, sourceName = "imported.puml"): GraphDocument {
  const used = new Set<string>();
  const aliasToId = new Map<string, string>();
  const nodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];
  const titleMatch = text.match(/^\s*title\s+(.+)$/im);
  const title = titleMatch?.[1]?.trim() || sourceName.replace(/\.[^.]+$/, "") || "Imported PlantUML model";

  const nodePattern =
    /^\s*(abstract\s+class|class|interface|enum|component|package|database|actor)\s+"?([A-Za-z0-9_.:$ -]+)"?(?:\s+as\s+([A-Za-z0-9_.$:-]+))?/gim;
  for (const match of text.matchAll(nodePattern)) {
    const rawKind = match[1].toLowerCase();
    const label = match[2].trim();
    const alias = match[3]?.trim() || label.replace(/[^A-Za-z0-9_]/g, "_");
    const kind: NodeKind =
      rawKind.includes("interface")
        ? "interface"
        : rawKind.includes("component")
          ? "service"
          : rawKind.includes("package")
            ? "package"
            : rawKind.includes("database")
              ? "database"
              : rawKind.includes("actor")
                ? "agent"
                : "class";
    const id = idFor(kind, label, used);
    aliasToId.set(alias, id);
    aliasToId.set(label, id);
    nodes.push({
      id,
      label,
      kind,
      stereotype: rawKind.replace(/\s+/g, " "),
      description: `Imported from ${sourceName}.`,
      uml: {
        elementType: kind === "service" ? "Component" : kind[0].toUpperCase() + kind.slice(1),
        visibility: "public",
      },
      metrics: metricsFor(label),
      members: [],
      status: "draft",
    });
  }

  const edgePattern = /^\s*([A-Za-z0-9_.$:-]+)\s+([.o*<|}-]*[-.]+[->|o*]+)\s+([A-Za-z0-9_.$:-]+)(?:\s*:\s*(.+))?/gim;
  let edgeIndex = 1;
  for (const match of text.matchAll(edgePattern)) {
    const sourceId = aliasToId.get(match[1]);
    const targetId = aliasToId.get(match[3]);
    if (!sourceId || !targetId) continue;
    const arrow = match[2];
    const relationship = arrow.includes("|>") ? "generalization" : arrow.includes("..") ? "dependency" : "association";
    edges.push({
      id: `edge-${edgeIndex}`,
      sourceId,
      targetId,
      kind: relationship === "dependency" ? "depends_on" : "calls",
      label: match[4]?.trim() || relationship,
      uml: {
        relationship,
        dashed: arrow.includes(".."),
        arrow: relationship === "generalization" ? "triangle" : "open",
      },
    });
    edgeIndex += 1;
  }

  return normalizeGraphDocument({
    ...createEmptyDocument(),
    id: `trd-${slugify(title)}-${Date.now().toString(36)}`,
    slug: slugify(title),
    title,
    summary: `Imported PlantUML model from ${sourceName}.`,
    nodes,
    edges,
  });
}

export function importCodeFiles(files: readonly TextFilePayload[]): GraphDocument {
  const used = new Set<string>();
  const nodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];
  const rootId = idFor("system", "Imported Codebase", used);

  nodes.push({
    id: rootId,
    label: "Imported Codebase",
    kind: "system",
    stereotype: "system",
    description: "Code imported into a 3D UML model.",
    uml: { elementType: "Model", visibility: "public" },
    metrics: { complexity: 42, churn: 12, risk: 18 },
    members: files.map((file) => file.name),
    status: "draft",
  });

  for (const file of files) {
    const packageId = idFor("package", file.name.replace(/\.[^.]+$/, ""), used);
    nodes.push({
      id: packageId,
      label: file.name.replace(/\.[^.]+$/, ""),
      kind: "package",
      parentId: rootId,
      stereotype: "source-file",
      packageName: file.name,
      description: `Source file imported from ${file.name}.`,
      uml: { elementType: "Package", visibility: "public" },
      metrics: metricsFor(file.name),
      members: [],
      status: "draft",
    });
    edges.push({ id: `contains-${rootId}-${packageId}`, sourceId: rootId, targetId: packageId, kind: "contains", label: "contains" });

    const symbols = Array.from(
      file.text.matchAll(/\b(export\s+)?(abstract\s+)?(class|interface|enum|struct|function)\s+([A-Za-z_$][A-Za-z0-9_$]*)/g),
    );
    const fallbackSymbols = symbols.length ? symbols : [[null, "", "", "class", file.name.replace(/\.[^.]+$/, "")]] as unknown as RegExpMatchArray[];
    for (const symbol of fallbackSymbols) {
      const rawKind = symbol[3];
      const label = symbol[4];
      const kind: NodeKind = rawKind === "interface" ? "interface" : rawKind === "function" ? "function" : "class";
      const id = idFor(kind, label, used);
      nodes.push({
        id,
        label,
        kind,
        parentId: packageId,
        stereotype: rawKind,
        packageName: file.name,
        description: `Imported ${rawKind} from ${file.name}.`,
        uml: {
          elementType: rawKind[0].toUpperCase() + rawKind.slice(1),
          visibility: "public",
          abstract: Boolean(symbol[2]),
          attributes: [],
          operations: kind === "function" ? [`+ ${label}()`] : [],
        },
        metrics: metricsFor(label),
        members: [],
        status: "draft",
      });
      edges.push({ id: `contains-${packageId}-${id}`, sourceId: packageId, targetId: id, kind: "contains", label: "contains" });
    }
  }

  return normalizeGraphDocument({
    ...createEmptyDocument(),
    id: `trd-imported-code-${Date.now().toString(36)}`,
    slug: "imported-codebase",
    title: "Imported Codebase",
    summary: "Code imported into a The Robot Draft 3D UML model.",
    nodes,
    edges,
  });
}

function nodeAlias(node: GraphNode) {
  return node.id.replace(/[^A-Za-z0-9_]/g, "_");
}

export function exportPlantUml(document: GraphDocument) {
  const lines = [
    "@startuml",
    `title ${document.title}`,
    ...document.nodes.map((node) => `${node.kind === "interface" ? "interface" : node.kind === "package" ? "package" : "class"} "${node.label}" as ${nodeAlias(node)}`),
    ...document.edges.map((edge) => `${nodeAlias({ id: edge.sourceId } as GraphNode)} --> ${nodeAlias({ id: edge.targetId } as GraphNode)} : ${edge.label}`),
    "@enduml",
  ];
  return lines.join("\n");
}

export function exportMermaid(document: GraphDocument) {
  const lines = [
    "classDiagram",
    ...document.nodes.map((node) => `  class ${nodeAlias(node)}["${node.label.replaceAll('"', "'")}"]`),
    ...document.edges.map((edge) => `  ${edge.sourceId.replace(/[^A-Za-z0-9_]/g, "_")} --> ${edge.targetId.replace(/[^A-Za-z0-9_]/g, "_")} : ${edge.label}`),
  ];
  return lines.join("\n");
}

export function exportDot(document: GraphDocument) {
  const lines = [
    `digraph "${document.slug}" {`,
    "  graph [rankdir=LR];",
    ...document.nodes.map((node) => `  "${node.id}" [label="${node.label.replaceAll('"', "'")}", shape=box];`),
    ...document.edges.map((edge) => `  "${edge.sourceId}" -> "${edge.targetId}" [label="${edge.label.replaceAll('"', "'")}"];`),
    "}",
  ];
  return lines.join("\n");
}

export function exportCodeSkeleton(document: GraphDocument) {
  const lines = [
    `// Generated from ${document.title}`,
    "namespace TheRobotDraft.RoundTrip;",
    "",
    ...document.nodes
      .filter((node) => node.kind === "class" || node.kind === "interface")
      .flatMap((node) => {
        const declaration = node.kind === "interface" ? `public interface I${node.label}` : `public class ${node.label}`;
        return [declaration, "{", ...(node.uml?.attributes ?? []).map((attr) => `    // ${attr}`), ...(node.uml?.operations ?? []).map((op) => `    // ${op}`), "}", ""];
      }),
  ];
  return lines.join("\n");
}

export function downloadText(filename: string, body: string, mimeType = "text/plain") {
  const blob = new Blob([body], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const anchor = window.document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  window.document.body.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
