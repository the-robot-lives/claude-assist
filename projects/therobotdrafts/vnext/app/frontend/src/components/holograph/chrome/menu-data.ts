import type { SkeletonLanguage, UmlRelationship } from "@/lib/holograph/document-io";
import type { NodeKind } from "@/lib/holograph/types";

/** Element kinds offered by the Concept D palette dock and the Model > Add Element menu.
 *
 * `nodeKind: null` means the vnext document model has no equivalent yet -- those chips and
 * menu rows render visibly disabled rather than being dropped or faked. */
export interface ElementKindSpec {
  key: ElementKindKey;
  label: string;
  glyph: string;
  nodeKind: NodeKind | null;
}

export type ElementKindKey =
  | "class"
  | "interface"
  | "enum"
  | "package"
  | "component"
  | "actor"
  | "datastore"
  | "note"
  | "region";

export const ELEMENT_KINDS: ElementKindSpec[] = [
  { key: "class", label: "Class", glyph: "Cl", nodeKind: "class" },
  { key: "interface", label: "Interface", glyph: "If", nodeKind: "interface" },
  { key: "enum", label: "Enum", glyph: "En", nodeKind: null },
  { key: "package", label: "Package", glyph: "Pk", nodeKind: "package" },
  { key: "component", label: "Component", glyph: "Co", nodeKind: "service" },
  { key: "actor", label: "Actor", glyph: "Ac", nodeKind: "agent" },
  { key: "datastore", label: "Datastore", glyph: "Db", nodeKind: "database" },
  { key: "note", label: "Note", glyph: "Nt", nodeKind: null },
  { key: "region", label: "Region", glyph: "Rg", nodeKind: null },
];

/** Everything the kind browser ("More…", ⇧⌘K) can arm — the palette's nine plus the
 * document kinds that have no chip of their own. */
export const KIND_BROWSER_ENTRIES: Array<{ label: string; nodeKind: NodeKind | null; family: string }> = [
  ...ELEMENT_KINDS.map((entry) => ({
    label: entry.label,
    nodeKind: entry.nodeKind,
    family: "Palette",
  })),
  { label: "System", nodeKind: "system", family: "Structure" },
  { label: "Service", nodeKind: "service", family: "Structure" },
  { label: "Function", nodeKind: "function", family: "Behaviour" },
  { label: "Agent", nodeKind: "agent", family: "Behaviour" },
];

export const RELATIONSHIP_LABELS: Record<UmlRelationship, string> = {
  association: "Association",
  dependency: "Dependency",
  generalization: "Generalization",
  realization: "Realization",
  composition: "Composition",
  aggregation: "Aggregation",
  deployment: "Deployment",
  trace: "Trace",
};

export type TrdCommandId =
  // ---- File
  | "file.new"
  | "file.open"
  | "file.save"
  | "file.saveAs"
  | `file.openRecent.${number}`
  | "file.import.plantuml"
  | "file.import.sourceFolder"
  | "file.export.trdyaml"
  | "file.export.plantuml"
  | "file.export.mermaid"
  | "file.export.json"
  | "file.export.dot"
  | `file.export.code.${SkeletonLanguage}`
  | "file.closeDiagram"
  // ---- Edit
  | "edit.undo"
  | "edit.redo"
  | "edit.cut"
  | "edit.copy"
  | "edit.paste"
  | "edit.duplicate"
  | "edit.delete.removeEverywhere"
  | "edit.find"
  | "edit.rename"
  // ---- Model
  | `model.add.${ElementKindKey}`
  | "model.add.more"
  | "model.members.addAttribute"
  | "model.members.addOperation"
  | "model.connect"
  | `model.relationship.${UmlRelationship}`
  // ---- Go
  | "go.commandPalette"
  | "go.jumpToElement"
  | "go.frameSelected"
  | "go.frameAll"
  | "go.trace.start"
  | "go.trace.close"
  // ---- View
  | "view.modelBrowser"
  | "view.inspector"
  | "view.outline"
  | "view.statusBar"
  | "view.elementPalette"
  | "view.camera.controls"
  | "view.camera.overview"
  | "view.camera.focus"
  | "view.camera.reset"
  | "view.appearance.traceNeighbors"
  | "view.focusMode"
  | "view.fullScreen"
  // ---- Code
  | "code.generateForSelection"
  // ---- Help
  | "help.keyboardShortcuts"
  | "help.sample.unityParity";

/** Keys into the workspace-provided `checks` record; a truthy value renders a ✓. */
export type TrdCheckId = string;

export interface MenuNode {
  label: string;
  kbd?: string;
  command?: TrdCommandId;
  check?: TrdCheckId;
  children?: MenuEntry[];
  /** Children are supplied at render time by the workspace (recents, window list). */
  dynamic?: "recents" | "windows";
}

export type MenuEntry = MenuNode | { separator: true };

export interface MenuDefinition {
  label: string;
  items: MenuEntry[];
}

export function isSeparator(entry: MenuEntry): entry is { separator: true } {
  return "separator" in entry;
}

const SEP: MenuEntry = { separator: true };

const codeSkeletonChildren: MenuEntry[] = [
  { label: "C#", command: "file.export.code.csharp" },
  { label: "TypeScript", command: "file.export.code.typescript" },
  { label: "Python", command: "file.export.code.python" },
  { label: "Java", command: "file.export.code.java" },
  { label: "Go", command: "file.export.code.go" },
];

const addElementChildren: MenuEntry[] = [
  ...ELEMENT_KINDS.map<MenuEntry>((entry) => ({
    label: entry.label,
    command: entry.nodeKind ? (`model.add.${entry.key}` as TrdCommandId) : undefined,
  })),
  SEP,
  { label: "More…", kbd: "⇧⌘K", command: "model.add.more" },
];

const relationshipChildren: MenuEntry[] = (Object.keys(RELATIONSHIP_LABELS) as UmlRelationship[]).map((kind) => ({
  label: RELATIONSHIP_LABELS[kind],
  command: `model.relationship.${kind}` as TrdCommandId,
  check: `relationship.${kind}`,
}));

const newFromModelChildren: MenuEntry[] = [
  {
    label: "UML",
    children: ["Class", "Sequence", "Package", "Component", "Deployment", "State", "Activity", "Use Case", "Object", "Timing"].map(
      (label) => ({ label }),
    ),
  },
  { label: "Data", children: ["ERD", "C4"].map((label) => ({ label })) },
  { label: "Process", children: ["BPMN", "DMN", "Flowchart"].map((label) => ({ label })) },
  { label: "Systems", children: ["SysML", "ArchiMate", "Network"].map((label) => ({ label })) },
  { label: "Sketch", children: ["Mind Map", "Whiteboard", "Wireframe"].map((label) => ({ label })) },
];

/** The nine Concept D menus, in demo order. Items without a `command` are rendered
 * disabled: the IA is complete, the wiring is not, and the spec forbids hiding either fact. */
export const MENUS: MenuDefinition[] = [
  {
    label: "File",
    items: [
      { label: "New Model", kbd: "⌘N", command: "file.new" },
      { label: "New Diagram…", kbd: "⇧⌘N" },
      { label: "New Page" },
      { label: "Open…", kbd: "⌘O", command: "file.open" },
      { label: "Open Recent", dynamic: "recents", children: [] },
      SEP,
      { label: "Save", kbd: "⌘S", command: "file.save" },
      { label: "Save As…", kbd: "⇧⌘S", command: "file.saveAs" },
      SEP,
      {
        label: "Import",
        children: [
          { label: "PlantUML…", command: "file.import.plantuml" },
          { label: "XMI…" },
          { label: "Mermaid…" },
          { label: "EA Project (.qea)…" },
          SEP,
          { label: "Source Code (paste)…" },
          { label: "Source Folder…", command: "file.import.sourceFolder" },
          { label: "Database (Postgres/MySQL)…" },
          { label: "From Image…" },
        ],
      },
      {
        label: "Export",
        children: [
          { label: "TRD YAML", command: "file.export.trdyaml" },
          { label: "TRD JSON", command: "file.export.json" },
          { label: "PlantUML", command: "file.export.plantuml" },
          { label: "Mermaid", command: "file.export.mermaid" },
          { label: "DOT (Graphviz)", command: "file.export.dot" },
          { label: "XMI" },
          { label: "EA Project (.qea)" },
          SEP,
          { label: "Code Skeleton", children: codeSkeletonChildren },
          SEP,
          { label: "Snapshot as PNG…" },
          { label: "Copy Snapshot", kbd: "⌃⌘C" },
          { label: "3D Scene (OBJ + MTL)…" },
        ],
      },
      SEP,
      { label: "Close Diagram", kbd: "⌘W", command: "file.closeDiagram" },
      { label: "Delete Diagram…" },
    ],
  },
  {
    label: "Edit",
    items: [
      { label: "Undo", kbd: "⌘Z", command: "edit.undo" },
      { label: "Redo", kbd: "⇧⌘Z", command: "edit.redo" },
      SEP,
      { label: "Cut", kbd: "⌘X", command: "edit.cut" },
      { label: "Copy", kbd: "⌘C", command: "edit.copy" },
      { label: "Paste", kbd: "⌘V", command: "edit.paste" },
      { label: "Duplicate", kbd: "⌘D", command: "edit.duplicate" },
      { label: "Paste Image as Node" },
      {
        label: "Delete",
        children: [
          { label: "Unlink from This Diagram", kbd: "⌫" },
          { label: "Remove from Model Everywhere", kbd: "⌥⌫", command: "edit.delete.removeEverywhere" },
        ],
      },
      SEP,
      { label: "Select All", kbd: "⌘A" },
      { label: "Select Volume", kbd: "⇧⌘A" },
      { label: "Find Element…", kbd: "⌘F", command: "edit.find" },
      { label: "Rename", kbd: "⏎", command: "edit.rename" },
    ],
  },
  {
    label: "Model",
    items: [
      { label: "Add Element", children: addElementChildren },
      {
        label: "Members",
        children: [
          { label: "Add Attribute", kbd: "⌥A", command: "model.members.addAttribute" },
          { label: "Add Operation", kbd: "⌥O", command: "model.members.addOperation" },
          { label: "Edit Members…" },
        ],
      },
      SEP,
      { label: "Connect", kbd: "C", command: "model.connect" },
      { label: "Relationship Type", children: relationshipChildren },
      SEP,
      {
        label: "Aspects",
        children: [
          { label: "Attach Aspect…" },
          { label: "Aspect Registry…" },
          { label: "Emit to Code…" },
          { label: "Ingest from Code…" },
        ],
      },
      {
        label: "Style",
        children: [{ label: "Color Swatches…" }, { label: "Attach Image to Face…" }, { label: "Avatar Editor…" }],
      },
      { label: "Validate Model", kbd: "⇧⌘V" },
      { label: "Model Properties…" },
    ],
  },
  {
    label: "Diagram",
    items: [
      { label: "New From Model", children: newFromModelChildren },
      { label: "Duplicate Diagram" },
      { label: "Link Element Here…" },
      SEP,
      {
        label: "Layout",
        children: [
          { label: "Cluster (post-import)" },
          { label: "Layered Hierarchy" },
          { label: "Force-Directed" },
          { label: "Grid" },
          { label: "AI Layout…" },
          SEP,
          { label: "Keep Hand Placements", check: "layout.keepHandPlacements" },
        ],
      },
      SEP,
      { label: "Previous Diagram", kbd: "⌘{" },
      { label: "Next Diagram", kbd: "⌘}" },
      { label: "Diagram Properties…" },
      { label: "Pages", children: [{ label: "Add Page…" }, { label: "Rename Page…" }] },
    ],
  },
  {
    label: "Code",
    items: [
      { label: "Generate for Selection", kbd: "⌘G", command: "code.generateForSelection" },
      { label: "Code Export Wizard…", kbd: "⇧⌘G" },
      {
        label: "Refactor",
        children: [{ label: "Rename Symbol…" }, { label: "Move to File…" }, { label: "AI Refactor…" }],
      },
      SEP,
      {
        label: "Shadow Files",
        children: [
          { label: "Open in Editor", kbd: "⇧⌘O" },
          { label: "Re-ingest Edits" },
          { label: "Watch for Changes" },
        ],
      },
      {
        label: "Database",
        children: [{ label: "Connect…" }, { label: "Diff vs Baseline" }, { label: "Emit Liquibase Changelog…" }],
      },
    ],
  },
  {
    label: "Go",
    items: [
      { label: "Command Palette", kbd: "⌘K", command: "go.commandPalette" },
      { label: "Jump to Element…", kbd: "⌘J", command: "go.jumpToElement" },
      { label: "Back", kbd: "⌃[" },
      { label: "Forward", kbd: "⌃]" },
      SEP,
      { label: "Frame Selected", kbd: "F", command: "go.frameSelected" },
      { label: "Frame All", kbd: "Home", command: "go.frameAll" },
      {
        label: "Z-Layer",
        children: [
          { label: "Up", kbd: "⌥↑" },
          { label: "Down", kbd: "⌥↓" },
          { label: "Jump…" },
          { label: "Follow Edge Across Layers", kbd: "⌥⏎" },
        ],
      },
      SEP,
      {
        label: "Trace",
        children: [
          { label: "Start Trace Here", kbd: "⌘T", command: "go.trace.start" },
          { label: "Open Call Site as Bubble" },
          { label: "Close Trace", command: "go.trace.close" },
          SEP,
          { label: "Launch Debug", kbd: "⌘R" },
          { label: "Continue", kbd: "⌃⌘Y" },
          { label: "Step", kbd: "F7" },
          { label: "Toggle Breakpoint", kbd: "⌘\\" },
        ],
      },
    ],
  },
  {
    label: "View",
    items: [
      { label: "Model Browser", kbd: "⌥⌘1", command: "view.modelBrowser", check: "view.modelBrowser" },
      { label: "Inspector", kbd: "⌥⌘2", command: "view.inspector", check: "view.inspector" },
      { label: "Outline", kbd: "⌥⌘3", command: "view.outline", check: "view.outline" },
      { label: "Element Palette", kbd: "⌥⌘4", command: "view.elementPalette", check: "view.elementPalette" },
      { label: "Status Bar", command: "view.statusBar", check: "view.statusBar" },
      SEP,
      {
        label: "Camera",
        children: [
          { label: "Camera Controls…", kbd: "⇧⌘C", command: "view.camera.controls" },
          { label: "Overview", command: "view.camera.overview" },
          { label: "Focus", command: "view.camera.focus" },
          { label: "Top" },
          { label: "Drag Mode Cycle", kbd: "⌥M" },
          { label: "Reset", command: "view.camera.reset" },
        ],
      },
      {
        label: "Appearance",
        children: [
          { label: "Grid" },
          { label: "Depth Cues" },
          { label: "Labels" },
          {
            label: "Trace Neighbors",
            command: "view.appearance.traceNeighbors",
            check: "appearance.traceNeighbors",
          },
          { label: "Regions" },
          {
            label: "Theme",
            children: [
              { label: "Dark", check: "theme.dark" },
              { label: "Light" },
              { label: "Edit Tokens…" },
            ],
          },
        ],
      },
      {
        label: "Overlays",
        children: [{ label: "Color by Metric" }, { label: "Dependency Cycles" }, { label: "Version Compare" }],
      },
      SEP,
      { label: "Focus Mode", kbd: "⌃⌘F", command: "view.focusMode", check: "view.focusMode" },
      { label: "Enter Full Screen", command: "view.fullScreen" },
    ],
  },
  {
    label: "Window",
    items: [
      { label: "Minimize", kbd: "⌘M" },
      { label: "Zoom" },
      SEP,
      { label: "Open Models", dynamic: "windows", children: [] },
    ],
  },
  {
    label: "Help",
    items: [
      { label: "Documentation" },
      { label: "Keyboard Shortcuts", kbd: "⌘/", command: "help.keyboardShortcuts" },
      SEP,
      {
        label: "Sample Models",
        children: [
          { label: "Unity Parity Example", command: "help.sample.unityParity" },
          { label: "Banking Domain" },
          { label: "Order Fulfillment (BPMN)" },
          { label: "Pump Station (SysML)" },
        ],
      },
      { label: "Guided Tour" },
    ],
  },
];

export interface MenuCommandEntry {
  command: TrdCommandId;
  /** Top-level menu label — the `em` category shown at the left of a palette row. */
  category: string;
  /** Menu path below the top level, e.g. "Export TRD YAML". */
  label: string;
  kbd: string;
}

/** Command-palette entries derived from the menu IA so the two can never drift apart. */
export function buildPaletteCommands(menus: MenuDefinition[] = MENUS): MenuCommandEntry[] {
  const out: MenuCommandEntry[] = [];

  function walk(entries: MenuEntry[], category: string, path: string[]) {
    for (const entry of entries) {
      if (isSeparator(entry)) continue;
      if (entry.command) {
        out.push({
          command: entry.command,
          category,
          label: [...path, entry.label].join(" "),
          kbd: entry.kbd ?? "",
        });
      }
      if (entry.children?.length) walk(entry.children, category, [...path, entry.label]);
    }
  }

  for (const menu of menus) walk(menu.items, menu.label, []);
  return out;
}
