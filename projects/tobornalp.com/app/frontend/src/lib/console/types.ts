// Console descriptor contract — config-driven table / detail / edit.
//
// Ported from npl-mcp's metadata-driven console CRUD system (diego-frontend).
// CANONICAL TYPE: this IS the primitive prop contract — DataTable / DetailView /
// EditForm are driven by a ConsoleDescriptor, and each domain supplies ONE descriptor.
//
// Three things beyond the bare data spec:
//   - `render` on a column/detail-field may be a STRING HINT resolved by the
//     cell-renderer registry (see render-hints.tsx) OR a function (domain logic).
//   - custom actions carry an optional `visibleWhen(ctx)` gate (RBAC seam).
//   - ConsoleContext carries the org + the viewer's advisory effective role.
//
// Org resolution note (tobornalp): orgId is the org UUID (tobornalp's api is
// UUID-keyed, and tobornalp routes ALSO carry the UUID in /app/[orgId]/). So
// unlike npl-mcp, orgSlug is usually redundant here — both api calls and route
// building use the same UUID. It's kept on the context for forward-compat.
import type { ReactNode } from "react";

export type ColumnAlign = "left" | "right" | "center";

/**
 * Reusable, value-based cell renderers resolved by the primitive from a string —
 * `render: "slugChip"` "just works". Operate on the cell value (row[key]) + row.
 * Domain-specific presentation stays a function renderer in the descriptor.
 */
export type CellRenderHint =
  | "slugChip"
  | "idChip"
  | "statusChip"
  | "relativeDate"
  | "identityChip";

/** A cell renderer: a registry hint, or a function for domain-specific presentation. */
export type CellRenderer<T> = CellRenderHint | ((row: T) => ReactNode);

/** Advisory context handed to the primitives + action gates. */
export interface ConsoleContext {
  /** Org UUID — what the `api.*` methods expect (tobornalp api is UUID-keyed). */
  orgId: string;
  /**
   * Canonical org SLUG for building app routes, when a domain wants slug-based URLs.
   * tobornalp routes carry the UUID, so this is optional / forward-compat.
   * Falls back to orgId when absent.
   */
  orgSlug?: string;
  /**
   * The viewer's effective role for the current resource (advisory only —
   * role is per-resource, NOT a JWT claim). Used to gate affordance VISIBILITY only;
   * the server guard remains the sole deny-closed boundary.
   */
  effectiveRole?: string;
}

export interface ColumnDef<T> {
  key: string;
  label: string;
  sortable?: boolean;
  align?: ColumnAlign;
  /** The clickable identity column (name/title) that owns the row→detail affordance. */
  primary?: boolean;
  /** CSS width or grow hint, e.g. "32%" / "8rem". */
  width?: string;
  /** Cell render: a registry hint string or a function. Omit for raw `row[key]`. */
  render?: CellRenderer<T>;
}

export interface FacetOption {
  value: string;
  label: string;
}

export interface FilterDef {
  key: string;
  label: string;
  type: "search" | "facet";
  /** Static facet options. Omit when the options are resolved dynamically (see `dynamic`). */
  options?: FacetOption[];
  /** Marks a facet whose options the primitive must resolve at runtime (e.g. projects). */
  dynamic?: boolean;
  /**
   * Multi-select facet: the user picks several values (OR-within-facet); the selected
   * values pass to api.list as an ARRAY under `key`. BE must accept the array param.
   * NOTE: tobornalp's listItems builds its querystring with URLSearchParams, which does
   * NOT serialize arrays — so prefer single-select facets unless the api adapter coerces.
   */
  multi?: boolean;
}

export type FieldType =
  | "text"
  | "textarea"
  | "slug"
  | "select"
  | "multiselect"
  | "toggle"
  | "date"
  | "number"
  | "reference";

export interface DetailFieldDef<T> {
  key: string;
  label: string;
  /** Full-width (long/rich fields: description, body). */
  span?: boolean;
  /** Cell render: a registry hint string or a function. */
  render?: CellRenderer<T>;
}

export interface DetailSection<T> {
  title: string;
  fields: DetailFieldDef<T>[];
}

export interface RelatedCollection {
  title: string;
  /** Domain key of the embedded read-only mini-DataTable. */
  domain: string;
  /**
   * Build the scope/query for the related list from the parent row. CONTRACT: every
   * key returned here MUST be an opt the TARGET descriptor's `api.list` actually
   * consumes — api.list ignores unknown keys silently, so a wrong key yields ALL rows,
   * not the scoped subset. Map the key to a real api.list filter before relying on it.
   */
  query: (row: Record<string, unknown>) => Record<string, unknown>;
}

export interface EditFieldDef {
  key: string;
  label: string;
  type: FieldType;
  required?: boolean;
  hint?: string;
  options?: FacetOption[];
  /** Resolve `options` at runtime (e.g. a project reference picker). */
  dynamic?: boolean;
  /** slug fields: the name field the slug auto-derives from. */
  derivesFrom?: string;
  /** reference fields: the target domain key. */
  referenceDomain?: string;
  /** Render disabled in edit (e.g. immutable slug post-create). */
  readOnly?: boolean;
}

export interface EditSection {
  title: string;
  fields: EditFieldDef[];
}

/** Built-in row actions the primitive wires from the descriptor's api methods. */
export type BuiltinRowAction = "view" | "edit" | "delete";

/**
 * A custom action (row kebab item or detail/edit button). `visibleWhen` is the RBAC
 * seam: when present, the action renders + is keyboard-reachable only if it returns
 * true. This gates VISIBILITY ONLY — never enforcement. A forged client just shows a
 * control the server rejects (the server guard is deny-closed).
 */
export interface ActionDef<T> {
  key: string;
  label: string;
  run: (row: T, ctx: ConsoleContext) => void | Promise<void>;
  /** Advisory PER-ROW visibility gate (RBAC). Omit = always visible. */
  visibleWhen?: (row: T, ctx: ConsoleContext) => boolean;
  /** Destructive styling + confirm (e.g. delete/moderate). */
  danger?: boolean;
}

export interface DescriptorActions<T> {
  /**
   * Row kebab actions, in order. Three forms:
   *   - built-in ("view"|"edit"|"delete") — wired by the primitive from the api methods.
   *   - a bare custom key (e.g. "archive") — dispatched via DataTable's `onAction(key,row)`;
   *     rendered only when a handler is supplied. Label is the title-cased key.
   *   - an ActionDef — custom + gate-able via `visibleWhen` (the RBAC seam).
   */
  rowActions?: (BuiltinRowAction | (string & {}) | ActionDef<T>)[];
  /** Bulk-select actions; omit/empty to disable bulk select (default off). */
  bulkActions?: (string | ActionDef<T>)[];
  /**
   * PER-ROW gates for the BUILT-IN edit/delete actions (orgs etc., where the viewer's
   * role varies per row). Omit = visible. INVARIANT: gates VISIBILITY / keyboard-
   * reachability ONLY — never enforcement. The server guard stays the sole deny-closed
   * boundary; a forged client that un-hides edit still 403s.
   */
  canEdit?: (row: T, ctx: ConsoleContext) => boolean;
  canDelete?: (row: T, ctx: ConsoleContext) => boolean;
  /** Override the kebab labels for the built-in actions. Omit = defaults. */
  builtinLabels?: { view?: string; edit?: string; delete?: string };
}

/**
 * Uniform data contract the primitives call. Each wraps the domain's `api.*`
 * method and UNWRAPS to the bare entity/array so the table/detail/edit don't need
 * to know each domain's envelope key ({items}/{queues}/...). `create`/`update`/
 * `remove` are optional so a domain can be read-only or lack an endpoint.
 */
export interface DescriptorApi<T, TInput> {
  list: (orgId: string, opts?: Record<string, unknown>) => Promise<T[]>;
  get: (orgId: string, id: string) => Promise<T>;
  create?: (orgId: string, input: TInput) => Promise<T>;
  update?: (orgId: string, id: string, input: Partial<TInput>) => Promise<T>;
  remove?: (orgId: string, id: string) => Promise<unknown>;
}

export interface ConsoleDescriptor<T = Record<string, unknown>, TInput = Partial<T>> {
  /** Stable domain key (also used to resolve related embedded tables). */
  domain: string;
  /** Singular/plural human labels for headings + empty states. */
  labels: { singular: string; plural: string };
  /** List route, ":org" substituted by the primitive (tobornalp: org UUID). */
  route: string;
  /** Field that identifies a row for detail/edit routing + keys. Defaults to "id". */
  idKey?: string;
  columns: ColumnDef<T>[];
  filters?: FilterDef[];
  detail: { sections: DetailSection<T>[]; related?: RelatedCollection[] };
  edit: { sections: EditSection[] };
  actions?: DescriptorActions<T>;
  api: DescriptorApi<T, TInput>;
  /** Default list render; "cards" keeps a legacy grid for visual-heavy domains. */
  display?: "table" | "cards";
}
