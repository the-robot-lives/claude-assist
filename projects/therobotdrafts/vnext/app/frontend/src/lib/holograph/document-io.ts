import type { EdgeKind, GraphDocument, GraphEdge, GraphNode, NodeKind } from "./types";

export interface TextFilePayload {
  name: string;
  text: string;
}

const nodeKinds = new Set<NodeKind>(["system", "package", "service", "class", "interface", "function", "database", "agent"]);
const edgeKinds = new Set<EdgeKind>(["contains", "calls", "depends_on", "publishes", "stores", "patches"]);

export type UmlRelationship = NonNullable<GraphEdge["uml"]>["relationship"];

export const UML_RELATIONSHIPS: UmlRelationship[] = [
  "association",
  "dependency",
  "generalization",
  "realization",
  "composition",
  "aggregation",
  "deployment",
  "trace",
];

// GraphEdge.kind must stay within EdgeKind or normalizeGraphDocument drops the edge on load.
export const relationshipEdgeKind: Record<UmlRelationship, EdgeKind> = {
  association: "calls",
  dependency: "depends_on",
  generalization: "depends_on",
  realization: "depends_on",
  composition: "contains",
  aggregation: "contains",
  deployment: "stores",
  trace: "depends_on",
};

export const relationshipStyle: Record<UmlRelationship, { dashed?: boolean; arrow: NonNullable<GraphEdge["uml"]>["arrow"] }> = {
  association: { arrow: "open" },
  dependency: { dashed: true, arrow: "open" },
  generalization: { arrow: "triangle" },
  realization: { dashed: true, arrow: "triangle" },
  composition: { arrow: "diamond" },
  aggregation: { arrow: "diamond" },
  deployment: { arrow: "open" },
  trace: { dashed: true, arrow: "open" },
};

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

function classifyArrow(arrow: string): { relationship: UmlRelationship; swap: boolean } {
  const dotted = arrow.includes(".");
  if (arrow.startsWith("<|") || arrow.endsWith("|>")) {
    // Triangle points at the parent; edge direction is child -> parent.
    return { relationship: dotted ? "realization" : "generalization", swap: arrow.startsWith("<|") };
  }
  if (arrow.startsWith("*") || arrow.endsWith("*")) {
    // Diamond sits on the whole; edge direction is whole -> part.
    return { relationship: "composition", swap: arrow.endsWith("*") };
  }
  if (arrow.startsWith("o") || arrow.endsWith("o")) {
    return { relationship: "aggregation", swap: arrow.endsWith("o") };
  }
  const leftHead = arrow.startsWith("<");
  if (dotted) return { relationship: "dependency", swap: leftHead };
  return { relationship: "association", swap: leftHead };
}

function plantUmlNodeKind(rawKind: string): NodeKind {
  if (rawKind.includes("interface")) return "interface";
  if (rawKind.includes("component")) return "service";
  if (rawKind.includes("package")) return "package";
  if (rawKind.includes("database")) return "database";
  if (rawKind.includes("actor")) return "agent";
  return "class";
}

export function importPlantUml(text: string, sourceName = "imported.puml"): GraphDocument {
  const used = new Set<string>();
  const aliasToId = new Map<string, string>();
  const nodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];
  const packageStack: Array<{ id: string; label: string }> = [];
  let title = "";
  let currentClass: GraphNode | null = null;

  const nodeDeclPattern =
    /^(abstract\s+class|abstract|class|interface|enum|entity|component|package|database|actor)\s+(?:"([^"]+)"|([A-Za-z0-9_.:$-]+))(?:\s+as\s+([A-Za-z0-9_.$:-]+))?(?:\s*<<\s*([^>]+?)\s*>>)?\s*(\{)?$/i;
  const edgePattern =
    /^(?:"([^"]+)"|([A-Za-z0-9_.$:-]+))\s*(?:"([^"]*)")?\s+((?:<\||<|\*|o)?[-.]+(?:\|>|\*|o|>)?)\s+(?:"([^"]*)")?\s*(?:"([^"]+)"|([A-Za-z0-9_.$:-]+))\s*(?::\s*(.+))?$/;
  const memberPattern = /^([+\-#~])?\s*(?:\{(?:abstract|static|field|method)\}\s*)?(.+?)$/;

  function packageQualifier() {
    return packageStack.map((entry) => entry.label).join(".") || undefined;
  }

  function registerNode(
    label: string,
    kind: NodeKind,
    options: { alias?: string; stereotype?: string; abstract?: boolean },
  ): GraphNode {
    const id = idFor(kind, label, used);
    const parent = packageStack.at(-1);
    const node: GraphNode = {
      id,
      label,
      kind,
      parentId: parent?.id,
      packageName: packageQualifier(),
      stereotype: options.stereotype ?? kind,
      description: `Imported from ${sourceName}.`,
      uml: {
        elementType: kind === "service" ? "Component" : kind[0].toUpperCase() + kind.slice(1),
        visibility: "public",
        abstract: options.abstract || undefined,
        attributes: [],
        operations: [],
      },
      metrics: metricsFor(label),
      members: [],
      status: "draft",
    };
    nodes.push(node);
    if (parent) {
      edges.push({ id: `contains-${parent.id}-${id}`, sourceId: parent.id, targetId: id, kind: "contains", label: "contains" });
    }
    if (options.alias) aliasToId.set(options.alias, id);
    aliasToId.set(label, id);
    aliasToId.set(label.replace(/[^A-Za-z0-9_]/g, "_"), id);
    return node;
  }

  function resolveEndpoint(raw: string): string {
    const existing = aliasToId.get(raw);
    if (existing) return existing;
    // PlantUML implicitly declares classes referenced only by relationships.
    return registerNode(raw, "class", {}).id;
  }

  let edgeIndex = 1;
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("'") || line.startsWith("@") || /^(hide|show|skinparam|scale|left|right|top|bottom)\b/i.test(line)) continue;

    const titleMatch = line.match(/^title\s+(.+)$/i);
    if (titleMatch) {
      title = titleMatch[1].trim();
      continue;
    }

    if (currentClass) {
      if (line === "}") {
        currentClass = null;
        continue;
      }
      if (/^[-=._]{2,}$/.test(line)) continue; // PlantUML section separators inside a body
      const member = line.match(memberPattern);
      if (member) {
        const marker = member[1];
        const body = member[2].trim();
        if (!body) continue;
        const formatted = marker ? `${marker} ${body}` : body;
        const uml = currentClass.uml!;
        if (body.includes("(")) uml.operations = [...(uml.operations ?? []), formatted];
        else uml.attributes = [...(uml.attributes ?? []), formatted];
        currentClass.members = [...(currentClass.members ?? []), formatted];
      }
      continue;
    }

    if (line === "}") {
      packageStack.pop();
      continue;
    }

    const decl = line.match(nodeDeclPattern);
    if (decl) {
      const rawKind = decl[1].toLowerCase().replace(/\s+/g, " ");
      const label = (decl[2] ?? decl[3]).trim();
      const alias = decl[4]?.trim();
      const stereotype = decl[5]?.trim();
      const opensBody = Boolean(decl[6]);
      const kind = plantUmlNodeKind(rawKind);
      const node = registerNode(label, kind, {
        alias,
        stereotype: stereotype ?? (rawKind === "abstract" ? "abstract class" : rawKind),
        abstract: rawKind.startsWith("abstract"),
      });
      if (opensBody) {
        if (kind === "package") packageStack.push({ id: node.id, label });
        else currentClass = node;
      }
      continue;
    }

    const edge = line.match(edgePattern);
    if (edge) {
      const leftRaw = (edge[1] ?? edge[2]).trim();
      const rightRaw = (edge[6] ?? edge[7]).trim();
      const arrow = edge[4];
      const { relationship, swap } = classifyArrow(arrow);
      let sourceId = resolveEndpoint(leftRaw);
      let targetId = resolveEndpoint(rightRaw);
      let sourceMultiplicity = edge[3]?.trim() || undefined;
      let targetMultiplicity = edge[5]?.trim() || undefined;
      if (swap) {
        [sourceId, targetId] = [targetId, sourceId];
        [sourceMultiplicity, targetMultiplicity] = [targetMultiplicity, sourceMultiplicity];
      }
      edges.push({
        id: `edge-${edgeIndex}`,
        sourceId,
        targetId,
        kind: relationshipEdgeKind[relationship],
        label: edge[8]?.trim() || relationship,
        uml: {
          relationship,
          sourceMultiplicity,
          targetMultiplicity,
          ...relationshipStyle[relationship],
        },
      });
      edgeIndex += 1;
      continue;
    }
  }

  const resolvedTitle = title || sourceName.replace(/\.[^.]+$/, "") || "Imported PlantUML model";
  return normalizeGraphDocument({
    ...createEmptyDocument(),
    id: `trd-${slugify(resolvedTitle)}-${Date.now().toString(36)}`,
    slug: slugify(resolvedTitle),
    title: resolvedTitle,
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

export type SkeletonLanguage = "csharp" | "typescript" | "python" | "java" | "go";

export const skeletonLanguages: Array<{ value: SkeletonLanguage; label: string; extension: string }> = [
  { value: "csharp", label: "C#", extension: "cs" },
  { value: "typescript", label: "TypeScript", extension: "ts" },
  { value: "python", label: "Python", extension: "py" },
  { value: "java", label: "Java", extension: "java" },
  { value: "go", label: "Go", extension: "go" },
];

function skeletonMembers(node: GraphNode) {
  return [...(node.uml?.attributes ?? []), ...(node.uml?.operations ?? [])];
}

export function exportCodeSkeleton(document: GraphDocument, language: SkeletonLanguage = "csharp") {
  const types = document.nodes.filter((node) => node.kind === "class" || node.kind === "interface");
  const safe = (label: string) => label.replace(/[^A-Za-z0-9_]/g, "_");

  if (language === "typescript") {
    return [
      `// Generated from ${document.title}`,
      "",
      ...types.flatMap((node) => [
        node.kind === "interface" ? `export interface ${safe(node.label)} {` : `export class ${safe(node.label)} {`,
        ...skeletonMembers(node).map((member) => `  // ${member}`),
        "}",
        "",
      ]),
    ].join("\n");
  }

  if (language === "python") {
    return [
      `# Generated from ${document.title}`,
      "",
      ...types.flatMap((node) => [
        `class ${safe(node.label)}:`,
        `    """${node.kind === "interface" ? "Interface" : "Class"} ${node.label}."""`,
        ...skeletonMembers(node).map((member) => `    # ${member}`),
        "    pass",
        "",
      ]),
    ].join("\n");
  }

  if (language === "java") {
    return [
      `// Generated from ${document.title}`,
      "package therobotdraft.roundtrip;",
      "",
      ...types.flatMap((node) => [
        node.kind === "interface" ? `public interface ${safe(node.label)} {` : `public class ${safe(node.label)} {`,
        ...skeletonMembers(node).map((member) => `    // ${member}`),
        "}",
        "",
      ]),
    ].join("\n");
  }

  if (language === "go") {
    return [
      `// Generated from ${document.title}`,
      "package roundtrip",
      "",
      ...types.flatMap((node) => [
        node.kind === "interface" ? `type ${safe(node.label)} interface {` : `type ${safe(node.label)} struct {`,
        ...skeletonMembers(node).map((member) => `\t// ${member}`),
        "}",
        "",
      ]),
    ].join("\n");
  }

  return [
    `// Generated from ${document.title}`,
    "namespace TheRobotDraft.RoundTrip;",
    "",
    ...types.flatMap((node) => {
      const declaration = node.kind === "interface" ? `public interface I${safe(node.label)}` : `public class ${safe(node.label)}`;
      return [declaration, "{", ...skeletonMembers(node).map((member) => `    // ${member}`), "}", ""];
    }),
  ].join("\n");
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
