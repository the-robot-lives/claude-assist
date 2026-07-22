// Boards console descriptor — tobornalp's planning boards (a board = an ItemQueue
// with a methodology, optional stages + iterations). tobornalp's existing board
// page (items/boards/[boardId]) is left intact for now; this descriptor registers
// the domain so the substrate has a second example and the registry can resolve it.
//
// REST gate (tobornalp api.ts): listQueues / getQueue / createQueue exist ->
// list + view + create wirable. There is NO updateQueue / deleteQueue, so edit and
// delete are intentionally omitted.
//
// listQueues(orgId, projectId?) only filters by project, so the list adapter maps
// the project_id facet to that single arg. methodology/scope are display-only here
// (the server ignores them); leave them out as facets to avoid implying they filter.
import { api, type ItemQueue, type Methodology } from "@/lib/api";
import type { ConsoleDescriptor } from "../types";

const titleCase = (s: string) => (s ? s.charAt(0).toUpperCase() + s.slice(1) : s);

// tobornalp's Methodology union, enumerated for the methodology picker.
const METHODOLOGIES: Methodology[] = ["kanban", "scrum", "waterfall", "spiral", "custom"];
const METHODOLOGY_OPTIONS = METHODOLOGIES.map((m) => ({ value: m, label: titleCase(m) }));

export interface QueueInput {
  name: string;
  slug: string;
  methodology?: Methodology;
  project_id?: string;
  description?: string;
}

export const boardsDescriptor: ConsoleDescriptor<ItemQueue, QueueInput> = {
  domain: "boards",
  labels: { singular: "Board", plural: "Boards" },
  route: "/app/:org/items/boards",
  columns: [
    { key: "name", label: "Name", primary: true, sortable: true, width: "30%" },
    { key: "methodology", label: "Type", sortable: true, render: (b) => titleCase(String(b.methodology ?? "—")) },
    { key: "slug", label: "Slug", render: "slugChip" },
    { key: "project_id", label: "Project", render: (b) => b.project_id ?? "Org-level" },
  ],
  filters: [
    { key: "search", label: "Search", type: "search" },
    // project_id maps to listQueues' single projectId arg (see the list adapter).
    { key: "project_id", label: "Project", type: "facet", dynamic: true },
  ],
  detail: {
    sections: [
      {
        title: "Identity",
        fields: [
          { key: "name", label: "Name" },
          { key: "slug", label: "Slug" },
          { key: "id", label: "ID" },
        ],
      },
      {
        title: "Type",
        fields: [{ key: "methodology", label: "Methodology", render: (b) => titleCase(String(b.methodology ?? "—")) }],
      },
      {
        title: "About",
        fields: [{ key: "description", label: "Description", span: true, render: (b) => b.description ?? "—" }],
      },
    ],
  },
  edit: {
    sections: [
      {
        title: "Board",
        fields: [
          { key: "name", label: "Name", type: "text", required: true },
          { key: "slug", label: "Slug", type: "slug", derivesFrom: "name", required: true },
          { key: "methodology", label: "Methodology", type: "select", options: METHODOLOGY_OPTIONS },
          { key: "project_id", label: "Project", type: "reference", referenceDomain: "projects", dynamic: true, hint: "Optional — scope this board to a project." },
          { key: "description", label: "Description", type: "textarea" },
        ],
      },
    ],
  },
  actions: { rowActions: ["view"] },
  api: {
    // listQueues only takes a single projectId; map the project_id facet opt to it.
    list: (orgId, opts) =>
      api.listQueues(orgId, (opts?.project_id as string | undefined) ?? undefined).then((r) => r.queues),
    get: (orgId, id) => api.getQueue(orgId, id).then((r) => r.queue),
    create: (orgId, input) => api.createQueue(orgId, input).then((r) => r.queue),
  },
};
