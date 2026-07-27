"use client";

// QueryEmbed — renders an ADR-002 ```query fence as a live item table, styled
// after the `.dbblock` recipe in design/concept-dark-neon/tobornalp-ui-concept.html
// (hairline card, --panel2 header strip echoing the query, mono throughout,
// --sel row hover).
//
// Failure is always a downgrade, never a blank doc: a query this component
// cannot parse or fetch renders as the plain code fence the markdown already
// was, plus a faint [WARN] line. The stored markdown is untouched either way —
// git, MCP and any other renderer still see an ordinary fenced block.
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { api, type Item } from "@/lib/api";
import { StatusBadge } from "@/components/ui";
import { cn } from "@/lib/cn";
import { applyClientClauses, describeQuery, parseQueryBlock, planQuery, type QueryPlan, type ParsedQuery } from "./queryBlock";

export interface QueryEmbedProps {
  /** Organization UUID — the items API and the item detail route are org-scoped. */
  orgId: string;
  /** Raw fence body. */
  source: string;
  className?: string;
}

type Compiled = { ok: true; query: ParsedQuery; plan: QueryPlan } | { ok: false; error: string };

type FetchState =
  | { status: "loading" }
  | { status: "ready"; items: Item[] }
  | { status: "error"; error: string };

// `Items.list/1` defaults to `limit: 50` and item_controller's index passes
// neither limit nor offset, so the items index is hard-capped at 50 rows,
// newest first, with no way to page and no total in the payload. A full result
// set is therefore indistinguishable from a truncated one except by hitting
// the ceiling exactly — so say so when we do rather than present a partial
// answer as complete. Remove this once the index accepts paging.
const SERVER_PAGE_SIZE = 50;

export function QueryEmbed({ orgId, source, className }: QueryEmbedProps) {
  const compiled = useMemo<Compiled>(() => {
    const parsed = parseQueryBlock(source);
    return parsed.ok
      ? { ok: true, query: parsed.query, plan: planQuery(parsed.query) }
      : { ok: false, error: parsed.error };
  }, [source]);

  const [state, setState] = useState<FetchState>({ status: "loading" });

  useEffect(() => {
    if (!compiled.ok) return;
    let live = true;
    setState({ status: "loading" });
    api
      .listItems(orgId, compiled.plan.params as Parameters<typeof api.listItems>[1])
      .then((res) => {
        if (live) setState({ status: "ready", items: res.items ?? [] });
      })
      .catch((err) => {
        if (live) setState({ status: "error", error: err instanceof Error ? err.message : "request failed" });
      });
    return () => {
      live = false;
    };
  }, [orgId, compiled]);

  if (!compiled.ok) return <FenceFallback source={source} warning={compiled.error} className={className} />;
  if (state.status === "error") {
    return <FenceFallback source={source} warning={`query failed — ${state.error}`} className={className} />;
  }

  const { query, plan } = compiled;
  const rows =
    state.status === "ready"
      ? applyClientClauses(state.items, plan.clientClauses).slice(0, query.limit ?? undefined)
      : [];

  const truncated = state.status === "ready" && state.items.length >= SERVER_PAGE_SIZE;

  const notes = [
    ...(query.requestedView === "table" ? [] : [`view: ${query.requestedView} → table (fallback)`]),
    ...(plan.clientClauses.length === 0
      ? []
      : [`filtered in-browser: ${plan.clientClauses.map((c) => `${c.field} ${c.op} ${c.raw}`).join(", ")}`]),
    ...(truncated ? [`showing the newest ${SERVER_PAGE_SIZE} items — the index does not page, so matches may be missing`] : []),
    ...query.warnings,
  ];

  return (
    <div className={cn("my-4 overflow-hidden rounded-card border border-line2 font-mono", className)}>
      <header className="flex flex-wrap items-center gap-2 border-b border-line bg-panel2 px-3 py-[7px] text-[11px] text-mut">
        <span>{describeQuery(query)}</span>
        <span className="ml-auto flex items-center gap-2">
          <span className="rounded-pill bg-acc px-[10px] py-px text-[10.5px] font-bold text-ground">table</span>
          <span>
            {state.status === "loading" ? "…" : rows.length} result{rows.length === 1 ? "" : "s"}
          </span>
        </span>
      </header>

      {notes.length > 0 && (
        <div className="border-b border-line px-3 py-1.5 text-[10.5px] leading-[1.6] text-faint">
          {notes.map((note, i) => (
            <div key={i}>{note}</div>
          ))}
        </div>
      )}

      {state.status === "loading" ? (
        <p className="px-3 py-3 text-[11.5px] text-faint" role="status">
          querying…
        </p>
      ) : rows.length === 0 ? (
        <p className="px-3 py-3 text-[11.5px] text-faint">no results</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-[12px]">
            <thead>
              <tr>
                {["key", "title", "status", "assignee"].map((h) => (
                  <th
                    key={h}
                    className="bg-panel px-3 py-1.5 text-left text-[10px] font-bold uppercase tracking-[0.06em] text-faint"
                  >
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((item) => {
                const href = `/app/${orgId}/items/${item.key ?? item.id}`;
                return (
                  <tr key={item.id} className="border-t border-line hover:bg-sel">
                    <td className="px-3 py-1.5 align-top">
                      <Link href={href} className="text-info no-underline hover:text-acc">
                        {item.key ?? "—"}
                      </Link>
                    </td>
                    <td className="px-3 py-1.5 align-top">
                      <Link href={href} className="text-ink no-underline hover:text-acc">
                        {item.title}
                      </Link>
                    </td>
                    <td className="px-3 py-1.5 align-top">
                      <StatusBadge status={item.status} />
                    </td>
                    <td className="px-3 py-1.5 align-top text-mut">{item.assignee || "—"}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

/** The fence as it would have rendered without this component, plus why. */
function FenceFallback({ source, warning, className }: { source: string; warning: string; className?: string }) {
  return (
    <div className={cn("my-3 max-w-[68ch]", className)}>
      <pre className="overflow-x-auto rounded-card border border-line bg-ground p-3 font-mono text-[12px] leading-[1.5] text-ink">
        <code className="font-mono">{source.replace(/\n$/, "")}</code>
      </pre>
      <p className="mt-1 font-mono text-[11px] text-faint">
        <span className="text-warn">[WARN]</span> {warning}
      </p>
    </div>
  );
}
