import {
  createEmptyDocument,
  normalizeGraphDocument,
  relationshipEdgeKind,
  relationshipStyle,
  type UmlRelationship,
} from "./document-io";
import type { GraphDocument, GraphEdge, GraphNode, NodeKind } from "./types";

// Native `.trd-yaml` reader/writer compatible with the Unity/C# tooling
// (Assets/Scripts/Authoring/Interchange/TrdYamlWriter.cs / TrdYamlReader.cs).
// The format is a YAML serialization of the IxModel interchange IR: a `name`,
// an `elements` pool (single-parent containment via `parentId`), `edges`, and
// `diagrams`. Elements/edges are one flow map per line; scalars follow the
// C# writer's single-quote rules ('' doubling, \n / \t escapes).

const HEADER = "# .trd-yaml — TheRobotDrafts native model (IxModel serialization)";

type FlowValue = string | FlowValue[] | FlowMap;
interface FlowMap {
  [key: string]: FlowValue;
}

// ------------------------------------------------------------------ scalars

const quoteTriggers = /[:#{}[\],*&!|>%@`?"]/;

function scalar(value: string): string {
  if (value.length === 0) return "''";
  const needsQuote =
    /^\s|\s$/.test(value) || /['\n\r\t]/.test(value) || quoteTriggers.test(value);
  if (!needsQuote) return value;
  const cleaned = value
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .replace(/\n/g, "\\n")
    .replace(/\t/g, "\\t");
  return `'${cleaned.replace(/'/g, "''")}'`;
}

function unescapeScalar(value: string): string {
  return value.replace(/\\n/g, "\n").replace(/\\t/g, "\t");
}

// ------------------------------------------------------------------ flow parser

class Cursor {
  constructor(
    public text: string,
    public pos = 0,
  ) {}

  peek() {
    return this.text[this.pos];
  }

  skipWhitespace() {
    while (this.pos < this.text.length && /\s/.test(this.text[this.pos])) this.pos += 1;
  }

  expect(char: string) {
    this.skipWhitespace();
    if (this.text[this.pos] !== char) {
      throw new Error(`trd-yaml: expected '${char}' at offset ${this.pos}`);
    }
    this.pos += 1;
  }
}

function parseQuoted(cursor: Cursor): string {
  cursor.expect("'");
  let out = "";
  while (cursor.pos < cursor.text.length) {
    const char = cursor.text[cursor.pos];
    if (char === "'") {
      if (cursor.text[cursor.pos + 1] === "'") {
        out += "'";
        cursor.pos += 2;
        continue;
      }
      cursor.pos += 1;
      return unescapeScalar(out);
    }
    out += char;
    cursor.pos += 1;
  }
  throw new Error("trd-yaml: unterminated quoted scalar");
}

function parseBare(cursor: Cursor): string {
  let out = "";
  while (cursor.pos < cursor.text.length && !",}]\n".includes(cursor.text[cursor.pos])) {
    out += cursor.text[cursor.pos];
    cursor.pos += 1;
  }
  return out.trim();
}

function parseFlowValue(cursor: Cursor): FlowValue {
  cursor.skipWhitespace();
  const char = cursor.peek();
  if (char === "{") {
    cursor.expect("{");
    const map: FlowMap = {};
    cursor.skipWhitespace();
    if (cursor.peek() === "}") {
      cursor.pos += 1;
      return map;
    }
    for (;;) {
      cursor.skipWhitespace();
      const key = cursor.peek() === "'" ? parseQuoted(cursor) : parseKey(cursor);
      cursor.expect(":");
      map[key] = parseFlowValue(cursor);
      cursor.skipWhitespace();
      if (cursor.peek() === ",") {
        cursor.pos += 1;
        continue;
      }
      cursor.expect("}");
      return map;
    }
  }
  if (char === "[") {
    cursor.expect("[");
    const items: FlowValue[] = [];
    cursor.skipWhitespace();
    if (cursor.peek() === "]") {
      cursor.pos += 1;
      return items;
    }
    for (;;) {
      items.push(parseFlowValue(cursor));
      cursor.skipWhitespace();
      if (cursor.peek() === ",") {
        cursor.pos += 1;
        continue;
      }
      cursor.expect("]");
      return items;
    }
  }
  if (char === "'") return parseQuoted(cursor);
  return parseBare(cursor);
}

function parseKey(cursor: Cursor): string {
  let out = "";
  while (cursor.pos < cursor.text.length && !":,}]".includes(cursor.text[cursor.pos])) {
    out += cursor.text[cursor.pos];
    cursor.pos += 1;
  }
  return out.trim();
}

function asString(value: FlowValue | undefined): string | undefined {
  // Bare (unquoted) `null` is the format's null literal; quoted 'null' arrives here
  // already unescaped and indistinguishable, but the C# writer never emits it quoted.
  return typeof value === "string" && value.length > 0 && value !== "null" ? value : undefined;
}

// ------------------------------------------------------------------ mappings

const elementTypeForKind: Record<NodeKind, string> = {
  system: "Package",
  package: "Package",
  service: "Component",
  class: "Class",
  interface: "Interface",
  function: "Class",
  database: "Database",
  agent: "Actor",
};

const kindForElementType: Record<string, NodeKind> = {
  Package: "package",
  Class: "class",
  Interface: "interface",
  Component: "service",
  Database: "database",
  Actor: "agent",
  Enum: "class",
  Struct: "class",
  DataType: "class",
  Table: "database",
  DeploymentNode: "service",
  Block: "class",
  Boundary: "package",
};

// IxEdgeType has no Deployment member; deployment round-trips as Dependency (label preserved).
const edgeTypeForRelationship: Record<UmlRelationship, string> = {
  association: "DirectedAssociation",
  dependency: "Dependency",
  generalization: "Generalization",
  realization: "Realization",
  composition: "Composition",
  aggregation: "Aggregation",
  deployment: "Dependency",
  trace: "Trace",
};

const relationshipForEdgeType: Record<string, UmlRelationship> = {
  Association: "association",
  DirectedAssociation: "association",
  Aggregation: "aggregation",
  Composition: "composition",
  Generalization: "generalization",
  Realization: "realization",
  Dependency: "dependency",
  Trace: "trace",
  Satisfy: "trace",
  Verify: "trace",
  Derive: "trace",
  Refine: "trace",
  Copy: "trace",
  NoteLink: "dependency",
  Extension: "generalization",
  Include: "dependency",
  Extend: "dependency",
};

const visibilityForMarker: Record<string, string> = {
  "+": "Public",
  "-": "Private",
  "#": "Protected",
  "~": "Package",
};

const markerForVisibility: Record<string, string> = {
  Public: "+",
  Private: "-",
  Protected: "#",
  Package: "~",
};

function metricsFor(label: string): GraphNode["metrics"] {
  const seed = Array.from(label).reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return { complexity: 18 + (seed % 43), churn: 8 + (seed % 29), risk: 10 + (seed % 38) };
}

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

// ------------------------------------------------------------------ writer

interface MemberRecord {
  name: string;
  isOperation: boolean;
  visibility: string;
  type?: string;
  params?: Array<{ name: string; type?: string }>;
  rawText: string;
}

function parseMemberString(raw: string, isOperation: boolean): MemberRecord {
  const match = raw.match(/^\s*([+\-#~])?\s*(.*)$/);
  const marker = match?.[1];
  const rest = (match?.[2] ?? raw).trim();
  const visibility = marker ? visibilityForMarker[marker] : "Public";
  if (isOperation) {
    const op = rest.match(/^([A-Za-z_$][A-Za-z0-9_$]*)\s*\(([^)]*)\)\s*(?::\s*(.+))?$/);
    if (op) {
      const params = op[2]
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean)
        .map((entry) => {
          const param = entry.match(/^([A-Za-z_$][A-Za-z0-9_$]*)\s*:\s*(.+)$/);
          return param ? { name: param[1], type: param[2].trim() } : { name: entry };
        });
      return {
        name: op[1],
        isOperation: true,
        visibility,
        type: op[3]?.trim(),
        params: params.length ? params : undefined,
        rawText: raw.trim(),
      };
    }
    return { name: rest, isOperation: true, visibility, rawText: raw.trim() };
  }
  const attr = rest.match(/^([A-Za-z_$][A-Za-z0-9_$]*)\s*:\s*(.+)$/);
  if (attr) return { name: attr[1], isOperation: false, visibility, type: attr[2].trim(), rawText: raw.trim() };
  return { name: rest, isOperation: false, visibility, rawText: raw.trim() };
}

function pair(key: string, value: string | undefined, parts: string[]) {
  if (value === undefined || value.length === 0) return;
  parts.push(`${key}: ${scalar(value)}`);
}

function memberFlow(member: MemberRecord): string {
  const parts: string[] = [];
  pair("name", member.name, parts);
  parts.push(`isOperation: ${member.isOperation ? "true" : "false"}`);
  pair("visibility", member.visibility, parts);
  pair("type", member.type, parts);
  if (member.params?.length) {
    const params = member.params
      .map((param) => {
        const paramParts: string[] = [];
        pair("name", param.name, paramParts);
        pair("type", param.type, paramParts);
        return `{ ${paramParts.join(", ")} }`;
      })
      .join(", ");
    parts.push(`params: [${params}]`);
  }
  pair("rawText", member.rawText, parts);
  return `{ ${parts.join(", ")} }`;
}

export function exportTrdYaml(document: GraphDocument): string {
  const lines: string[] = [HEADER];
  if (document.title) lines.push(`name: ${scalar(document.title)}`);

  if (document.nodes.length) {
    lines.push("elements:");
    for (const node of document.nodes) {
      const parts: string[] = [];
      pair("id", node.id, parts);
      parts.push(`type: ${elementTypeForKind[node.kind] ?? "Class"}`);
      pair("name", node.label, parts);
      pair("parentId", node.parentId, parts);
      pair("stereotype", node.stereotype, parts);
      if (node.uml?.abstract) parts.push("isAbstract: true");
      pair("documentation", node.description, parts);
      const members = [
        ...(node.uml?.attributes ?? []).map((raw) => parseMemberString(raw, false)),
        ...(node.uml?.operations ?? []).map((raw) => parseMemberString(raw, true)),
      ];
      if (members.length) parts.push(`members: [${members.map(memberFlow).join(", ")}]`);
      lines.push(`  - { ${parts.join(", ")} }`);
    }
  }

  // Containment travels via parentId in the elements pool; plain "contains" edges are
  // structural duplicates and are not emitted.
  const exportEdges = document.edges.filter((edge) => !(edge.kind === "contains" && !edge.uml));
  if (exportEdges.length) {
    lines.push("edges:");
    for (const edge of exportEdges) {
      const parts: string[] = [];
      pair("id", edge.id, parts);
      const relationship = edge.uml?.relationship;
      parts.push(`type: ${relationship ? edgeTypeForRelationship[relationship] : "DirectedAssociation"}`);
      pair("from", edge.sourceId, parts);
      pair("to", edge.targetId, parts);
      pair("label", edge.label, parts);
      pair("fromMultiplicity", edge.uml?.sourceMultiplicity, parts);
      pair("toMultiplicity", edge.uml?.targetMultiplicity, parts);
      lines.push(`  - { ${parts.join(", ")} }`);
    }
  }

  lines.push("diagrams:");
  lines.push(
    `  - { id: d1, name: ${scalar(document.title || "TRD model")}, kind: class, layoutProvenance: Synthesized }`,
  );
  return `${lines.join("\n")}\n`;
}

// ------------------------------------------------------------------ reader

export function looksLikeTrdYaml(text: string, fileName = ""): boolean {
  if (/\.trd[-.]ya?ml$/i.test(fileName)) return true;
  const head = text.trimStart();
  return head.startsWith("# .trd-yaml") || /^name:.*\n(?:.*\n)*?elements:\s*\n/m.test(head);
}

export function importTrdYaml(text: string, sourceName = "imported.trd-yaml"): GraphDocument {
  let title = "";
  const elements: FlowMap[] = [];
  const edgeMaps: FlowMap[] = [];
  type Section = "elements" | "edges" | "diagrams";
  let section: Section | null = null;

  for (const rawLine of text.split(/\r?\n/)) {
    if (!rawLine.trim() || rawLine.trim().startsWith("#")) continue;
    const nameMatch = rawLine.match(/^name:\s*(.+)$/);
    if (nameMatch && section === null) {
      const cursor = new Cursor(nameMatch[1].trim());
      title = String(parseFlowValue(cursor));
      continue;
    }
    const sectionMatch = rawLine.match(/^(elements|edges|diagrams):\s*$/);
    if (sectionMatch) {
      section = sectionMatch[1] as Section;
      continue;
    }
    const itemMatch = rawLine.match(/^\s+-\s+(\{.*\})\s*$/);
    if (itemMatch && section) {
      const value = parseFlowValue(new Cursor(itemMatch[1]));
      if (typeof value === "object" && !Array.isArray(value)) {
        if (section === "elements") elements.push(value);
        else if (section === "edges") edgeMaps.push(value);
        // diagram items (and their nodes: placements) are layout metadata; ignored here.
      }
    }
  }

  const nodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];

  for (const element of elements) {
    const id = asString(element.id);
    const label = asString(element.name) ?? id ?? "Element";
    if (!id) continue;
    const elementType = asString(element.type) ?? "Class";
    const kind = kindForElementType[elementType] ?? "class";
    const attributes: string[] = [];
    const operations: string[] = [];
    if (Array.isArray(element.members)) {
      for (const raw of element.members) {
        if (typeof raw !== "object" || Array.isArray(raw)) continue;
        const member = raw as FlowMap;
        const rawText = asString(member.rawText);
        const marker = markerForVisibility[asString(member.visibility) ?? "Public"] ?? "+";
        const memberName = asString(member.name) ?? "member";
        const memberType = asString(member.type);
        const isOperation = member.isOperation === "true";
        const fallback = isOperation
          ? `${marker} ${memberName}(${
              Array.isArray(member.params)
                ? member.params
                    .map((param) =>
                      typeof param === "object" && !Array.isArray(param)
                        ? `${asString((param as FlowMap).name) ?? ""}${asString((param as FlowMap).type) ? ` : ${asString((param as FlowMap).type)}` : ""}`
                        : "",
                    )
                    .join(", ")
                : ""
            })${memberType ? ` : ${memberType}` : ""}`
          : `${marker} ${memberName}${memberType ? ` : ${memberType}` : ""}`;
        const entry = rawText ?? fallback;
        if (isOperation) operations.push(entry);
        else attributes.push(entry);
      }
    }
    nodes.push({
      id,
      label,
      kind,
      parentId: asString(element.parentId),
      stereotype: asString(element.stereotype),
      description: asString(element.documentation) ?? `Imported from ${sourceName}.`,
      uml: {
        elementType,
        visibility: "public",
        abstract: element.isAbstract === "true" || undefined,
        attributes,
        operations,
      },
      metrics: metricsFor(label),
      members: [...attributes, ...operations],
      status: "draft",
    });
  }

  const nodeIds = new Set(nodes.map((node) => node.id));
  for (const node of nodes) {
    if (node.parentId && nodeIds.has(node.parentId)) {
      edges.push({
        id: `contains-${node.parentId}-${node.id}`,
        sourceId: node.parentId,
        targetId: node.id,
        kind: "contains",
        label: "contains",
      });
    }
  }

  for (const edge of edgeMaps) {
    const from = asString(edge.from);
    const to = asString(edge.to);
    if (!from || !to) continue;
    const edgeType = asString(edge.type) ?? "DirectedAssociation";
    const relationship = relationshipForEdgeType[edgeType] ?? "association";
    edges.push({
      id: asString(edge.id) ?? `edge-${edges.length + 1}`,
      sourceId: from,
      targetId: to,
      kind: relationshipEdgeKind[relationship],
      label: asString(edge.label) ?? relationship,
      uml: {
        relationship,
        sourceMultiplicity: asString(edge.fromMultiplicity),
        targetMultiplicity: asString(edge.toMultiplicity),
        ...relationshipStyle[relationship],
      },
    });
  }

  const resolvedTitle = title || sourceName.replace(/\.[^.]+$/, "") || "Imported TRD model";
  return normalizeGraphDocument({
    ...createEmptyDocument(),
    id: `trd-${slugify(resolvedTitle)}-${Date.now().toString(36)}`,
    slug: slugify(resolvedTitle),
    title: resolvedTitle,
    summary: `Imported .trd-yaml model from ${sourceName}.`,
    nodes,
    edges,
  });
}
