// queryBlock — parser + planner for the ```query fences described in ADR-002
// ("inline databases"). Pure logic, no React, so the grammar can be reasoned
// about (and tested) apart from the rendering in QueryEmbed.tsx.
//
// Grammar (yaml-ish, one directive per line, `#` starts a trailing comment):
//
//   from:  items                 -- required; `items` is the only wired source
//   where: <field> <op> <value>  -- repeatable; clauses AND together
//   view:  table | board | list  -- optional, default table
//   limit: <n>                   -- optional
//
// `<op>` is `=`, `!=` or `~` (contains). `<value>` may be a comma-separated
// list, which reads as "any of" for `=`/`~` and "none of" for `!=`; values may
// be quoted to keep commas or spaces.
//
// Clauses are split between the two places they can run. `=` on a field the
// items index actually filters on (see SERVER_PARAM) becomes a request param;
// everything else — other operators, custom fields, `tag` — is applied to the
// fetched list in the browser. That is a deliberate stopgap: it is correct for
// the page sizes this embed serves and needs no backend change, but it filters
// only what one unpaginated request returned.
import type { Item } from "@/lib/api";

export type QueryOp = "=" | "!=" | "~";
export type QueryView = "table" | "board" | "list";

export interface QueryClause {
  field: string;
  op: QueryOp;
  /** Right-hand side verbatim, for echoing the query back in the header. */
  raw: string;
  /** Unquoted, comma-split comparands. Case preserved — server filters are exact. */
  values: string[];
}

export interface ParsedQuery {
  from: string;
  clauses: QueryClause[];
  /** What the author asked for; only `table` is implemented. */
  requestedView: QueryView;
  limit: number | null;
  /** Non-fatal complaints, surfaced as a faint note strip. */
  warnings: string[];
}

export interface QueryPlan {
  /**
   * Filters handed to `api.listItems`. Kept as a loose record rather than the
   * declared param type: every one of these reaches the same `maybe_filter`,
   * which accepts a list on any field, but api.ts types the id-shaped params as
   * single strings. The call site casts, same as the items console descriptor.
   */
  params: Record<string, string | string[]>;
  /** Filters that have to run against the fetched rows. */
  clientClauses: QueryClause[];
}

export type ParseResult = { ok: true; query: ParsedQuery } | { ok: false; error: string };

// Fields the items index endpoint filters server-side, keyed by the names an
// author may plausibly write. Mirrors api.listItems params / item_controller's
// maybe_opt chain.
const SERVER_PARAM: Record<string, string> = {
  status: "status",
  type: "item_type",
  item_type: "item_type",
  priority: "priority",
  assignee: "assignee",
  owner: "assignee",
  project: "project_id",
  project_id: "project_id",
  queue: "queue_id",
  queue_id: "queue_id",
  parent: "parent_id",
  parent_id: "parent_id",
  stage: "stage_id",
  stage_id: "stage_id",
  iteration: "iteration_id",
  iteration_id: "iteration_id",
};

// Author-facing synonyms resolved before reading a value off an item.
const FIELD_ALIAS: Record<string, string> = {
  type: "item_type",
  owner: "assignee",
  project: "project_id",
  queue: "queue_id",
  parent: "parent_id",
  stage: "stage_id",
  iteration: "iteration_id",
  tag: "tags",
  label: "tags",
  labels: "tags",
};

const VIEWS: readonly string[] = ["table", "board", "list"];
const CLAUSE_RE = /^([A-Za-z_][A-Za-z0-9_.]*)\s*(!=|=|~)\s*(.*)$/;

export function parseQueryBlock(source: string): ParseResult {
  const warnings: string[] = [];
  const clauses: QueryClause[] = [];
  let from: string | null = null;
  let requestedView: QueryView = "table";
  let limit: number | null = null;

  for (const rawLine of source.split(/\r?\n/)) {
    const line = stripComment(rawLine).trim();
    if (!line) continue;

    const sep = line.indexOf(":");
    if (sep === -1) {
      warnings.push(`ignored line (expected \`key: value\`): ${line}`);
      continue;
    }
    const key = line.slice(0, sep).trim().toLowerCase();
    const value = line.slice(sep + 1).trim();

    switch (key) {
      case "from":
        from = value.toLowerCase();
        break;

      case "where": {
        const m = CLAUSE_RE.exec(value);
        if (!m) {
          warnings.push(`ignored where clause: ${value}`);
          break;
        }
        const [, field, op, rhs] = m;
        const values = splitValues(rhs);
        if (values.length === 0) {
          warnings.push(`ignored where clause (no value): ${value}`);
          break;
        }
        clauses.push({ field: field.toLowerCase(), op: op as QueryOp, raw: rhs.trim(), values });
        break;
      }

      case "view": {
        const v = value.toLowerCase();
        if (VIEWS.includes(v)) requestedView = v as QueryView;
        else warnings.push(`unknown view \`${value}\` — using table`);
        break;
      }

      case "limit": {
        const n = Number.parseInt(value, 10);
        if (Number.isFinite(n) && n > 0) limit = n;
        else warnings.push(`ignored limit \`${value}\``);
        break;
      }

      default:
        warnings.push(`unknown directive \`${key}\``);
    }
  }

  if (!from) return { ok: false, error: "missing `from:` — expected `from: items`" };
  if (from !== "items") {
    return { ok: false, error: `unsupported source \`${from}\` — only \`from: items\` is wired up` };
  }
  return { ok: true, query: { from, clauses, requestedView, limit, warnings } };
}

/** Split a parsed query into request params and leftover in-browser filters. */
export function planQuery(query: ParsedQuery): QueryPlan {
  const params: QueryPlan["params"] = {};
  const clientClauses: QueryClause[] = [];

  for (const clause of query.clauses) {
    const param = clause.op === "=" ? SERVER_PARAM[clause.field] : undefined;
    // One param per field: a second `=` on the same field would widen the
    // result (the backend treats a list as `in`) rather than narrow it, so the
    // repeat runs in the browser where AND still means AND.
    if (param && !(param in params)) {
      params[param] = clause.values.length === 1 ? clause.values[0] : clause.values;
    } else {
      clientClauses.push(clause);
    }
  }
  return { params, clientClauses };
}

/** Apply the clauses the API could not. */
export function applyClientClauses(items: Item[], clauses: QueryClause[]): Item[] {
  if (clauses.length === 0) return items;
  return items.filter((item) => clauses.every((clause) => matches(item, clause)));
}

/** The query echoed back for the embed's header strip. */
export function describeQuery(query: ParsedQuery): string {
  const head = `▦ ${query.from}`;
  if (query.clauses.length === 0) return head;
  const where = query.clauses.map((c) => `${c.field} ${c.op} ${c.raw}`).join(" and ");
  return `${head} · where ${where}`;
}

// ── internals ───────────────────────────────────────────────────────────────

// A `#` only opens a comment at line start or after whitespace, so a value like
// `title ~ #1` survives.
function stripComment(line: string): string {
  return line.replace(/(^|\s)#.*$/, "$1");
}

function splitValues(rhs: string): string[] {
  return rhs
    .split(",")
    .map((v) => unquote(v.trim()))
    .filter((v) => v.length > 0);
}

function unquote(value: string): string {
  const m = /^(["'])([\s\S]*)\1$/.exec(value);
  return m ? m[2] : value;
}

function matches(item: Item, clause: QueryClause): boolean {
  const actual = fieldValues(item, clause.field);
  const wanted = clause.values.map((v) => v.toLowerCase());

  switch (clause.op) {
    case "=":
      return actual.some((a) => wanted.includes(a));
    case "!=":
      // A field the item doesn't carry is "not equal" — an item with no tags
      // genuinely does not have `tag = governance`.
      return !actual.some((a) => wanted.includes(a));
    case "~":
      return actual.some((a) => wanted.some((w) => a.includes(w)));
  }
}

/** Every lowercased string an item offers under `field`, flattening tag lists. */
function fieldValues(item: Item, field: string): string[] {
  const name = FIELD_ALIAS[field] ?? field;
  const record = item as unknown as Record<string, unknown>;
  const custom = (item.custom_fields ?? {}) as Record<string, unknown>;

  let raw: unknown = record[name];
  if (raw === undefined || raw === null) raw = custom[name];
  if (raw === undefined || raw === null) raw = custom[field];
  return flattenScalars(raw);
}

function flattenScalars(raw: unknown): string[] {
  if (raw === null || raw === undefined) return [];
  if (Array.isArray(raw)) return raw.flatMap(flattenScalars);
  if (typeof raw === "object") return [];
  return [String(raw).toLowerCase()];
}
