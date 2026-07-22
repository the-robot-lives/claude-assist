// Items console descriptor — tobornalp's work-tracking domain (tobornalp calls
// them "items"). Exercises facets, project scope, status/priority/type/owner.
//
// REST gate (tobornalp api.ts): listItems / getItem / createItem / updateItem /
// deleteItem all exist. rowActions surfaces view + edit only (faithful npl-mcp
// port; a delete affordance with a confirm flow is a deliberate follow-on).
//
// Facet keys mirror the snake_case params api.listItems consumes (status,
// item_type, priority, assignee, project_id) so the primitive passes them
// straight through. They are MULTI-select: api.listItems now accepts
// `string | string[]` for status/item_type/priority/assignee, and buildQuery
// serializes arrays as `key[]=v` (Plug parses them into the BE `in` filter via
// Items.maybe_filter/2). Project stays single (it's the scope).
//
// Saved views: this domain persists list views under entity_type "item" /
// view_type "list". The scope is co-exported (see itemsSavedViewScope) so the
// list page can wire SavedViewsToolbar without touching the shared descriptor
// type contract (which has no savedView field yet).
import { api, type Item, type ItemInput } from "@/lib/api";
import type { ConsoleDescriptor } from "../types";
import { ITEM_PRIORITY_OPTIONS } from "../options";

const PRIORITIES = ITEM_PRIORITY_OPTIONS;

/**
 * Scope under which item list-views are saved/loaded. Co-exported (rather than
 * living on the descriptor) because the shared ConsoleDescriptor type has no
 * saved-view field; the list page hands this straight to the SavedViewsToolbar.
 */
export const itemsSavedViewScope = {
  entity_type: "item",
  view_type: "list",
} as const;

export const itemsDescriptor: ConsoleDescriptor<Item, ItemInput> = {
  domain: "items",
  labels: { singular: "Item", plural: "Items" },
  route: "/app/:org/items",
  columns: [
    { key: "title", label: "Title", primary: true, sortable: true, width: "34%" },
    { key: "key", label: "Key", sortable: true, width: "8rem", render: (it) => it.key ?? "—" },
    { key: "item_type", label: "Type", sortable: true },
    { key: "status", label: "Status", sortable: true, render: "statusChip" },
    { key: "priority", label: "Priority", sortable: true, render: (it) => it.priority ?? "—" },
    { key: "assignee", label: "Owner", sortable: true, render: (it) => it.assignee ?? "—" },
    { key: "updated_at", label: "Updated", sortable: true, align: "right", render: "relativeDate" },
  ],
  filters: [
    { key: "search", label: "Search", type: "search" },
    // facet keys mirror api.listItems opts so the primitive passes them through.
    // multi: true → FacetMultiSelect → status[]/item_type[]/priority[]/assignee[]
    // → BE `in` filter (OR-within-facet). project_id stays single (it's scope).
    { key: "status", label: "Status", type: "facet", dynamic: true, multi: true },
    { key: "item_type", label: "Type", type: "facet", dynamic: true, multi: true },
    { key: "priority", label: "Priority", type: "facet", options: PRIORITIES, multi: true },
    { key: "assignee", label: "Owner", type: "facet", dynamic: true, multi: true },
    { key: "project_id", label: "Project", type: "facet", dynamic: true },
  ],
  detail: {
    sections: [
      {
        title: "Overview",
        fields: [
          { key: "title", label: "Title" },
          { key: "key", label: "Key", render: (it) => it.key ?? "—" },
          { key: "item_type", label: "Type" },
          { key: "status", label: "Status", render: "statusChip" },
          { key: "priority", label: "Priority", render: (it) => it.priority ?? "—" },
          { key: "assignee", label: "Owner", render: (it) => it.assignee ?? "—" },
          { key: "reporter", label: "Reporter", render: (it) => it.reporter ?? "—" },
        ],
      },
      {
        title: "Description",
        fields: [{ key: "description", label: "Description", span: true, render: (it) => it.description ?? "—" }],
      },
      {
        title: "Meta",
        fields: [
          { key: "id", label: "ID" },
          { key: "project_id", label: "Project", render: (it) => it.project_id ?? "—" },
          { key: "parent_id", label: "Parent", render: (it) => it.parent_id ?? "—" },
          { key: "queue_id", label: "Board", render: (it) => it.queue_id ?? "—" },
          { key: "stage_id", label: "Stage", render: (it) => it.stage_id ?? "—" },
          { key: "iteration_id", label: "Iteration", render: (it) => it.iteration_id ?? "—" },
          { key: "inserted_at", label: "Created", render: "relativeDate" },
          { key: "updated_at", label: "Updated", render: "relativeDate" },
        ],
      },
    ],
    // NOTE: no related sub-items — listItems has no parent_id filter, so a
    // {parentId} scope would return ALL items (the wrong-key footgun). Add when
    // listItems accepts a parent_id param.
  },
  edit: {
    sections: [
      {
        title: "Item",
        fields: [
          { key: "title", label: "Title", type: "text", required: true },
          { key: "description", label: "Description", type: "textarea" },
          { key: "item_type", label: "Type", type: "select", dynamic: true, required: true, hint: "From the org/project item-type definitions." },
          { key: "status", label: "Status", type: "select", dynamic: true },
          { key: "priority", label: "Priority", type: "select", options: PRIORITIES },
          { key: "assignee", label: "Owner", type: "text", hint: "User handle (optional)." },
          { key: "project_id", label: "Project", type: "reference", referenceDomain: "projects", dynamic: true, hint: "Optional — scope to a project." },
        ],
      },
    ],
  },
  actions: { rowActions: ["view", "edit"] },
  api: {
    list: (orgId, opts) =>
      api.listItems(orgId, opts as Parameters<typeof api.listItems>[1]).then((r) => r.items),
    get: (orgId, id) => api.getItem(orgId, id).then((r) => r.item),
    create: (orgId, input) => api.createItem(orgId, input).then((r) => r.item),
    update: (orgId, id, input) => api.updateItem(orgId, id, input).then((r) => r.item),
  },
};
