"use client";

import { Suspense, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useParams, usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  AdminApiError,
  adminShowList,
  adminListSignups,
  adminFetchAllSignups,
  collectAttributeKeys,
  optInMode,
  signupsToCsv,
  downloadCsv,
  type AdminList,
  type AdminSignup,
} from "@/components/admin/admin-fetch";
import {
  BackLink,
  EmptyState,
  ErrorPanel,
  OptInBadge,
  Badge,
  SignupStatusBadge,
  SkeletonRows,
} from "@/components/admin/ui";
import { SignupDetailPanel } from "@/components/admin/signup-detail-panel";

const PER_PAGE = 50;
const STATUS_OPTIONS = [
  { value: "", label: "All statuses" },
  { value: "pending_optin", label: "Pending opt-in" },
  { value: "subscribed", label: "Subscribed" },
  { value: "unsubscribed", label: "Unsubscribed" },
  { value: "bounced", label: "Bounced" },
];
type SortKey = "email" | "status" | "created_at";
const DEFAULT_SORT: SortKey = "created_at";
const DEFAULT_ORDER: "asc" | "desc" = "desc";

function attrValueString(v: unknown): string {
  if (v === null || v === undefined) return "";
  if (Array.isArray(v)) return v.join(", ");
  if (typeof v === "object") return JSON.stringify(v);
  return String(v);
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return isNaN(d.getTime()) ? iso : d.toLocaleDateString();
}

function SignupsInner() {
  const params = useParams<{ projectId: string; listId: string }>();
  const projectId = params.projectId;
  const listId = params.listId;
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const q = searchParams.get("q") ?? "";
  const status = searchParams.get("status") ?? "";
  const sort = (searchParams.get("sort") as SortKey) || DEFAULT_SORT;
  const order = (searchParams.get("order") as "asc" | "desc") || DEFAULT_ORDER;
  const page = Math.max(1, parseInt(searchParams.get("page") ?? "1", 10) || 1);

  // Server-default = the case the backend can paginate directly (status + offset).
  const serverDefault = q.trim() === "" && sort === DEFAULT_SORT && order === DEFAULT_ORDER;

  const [list, setList] = useState<AdminList | null>(null);
  const [rows, setRows] = useState<AdminSignup[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);
  const [exporting, setExporting] = useState(false);
  const [selected, setSelected] = useState<AdminSignup | null>(null);

  // Local search box (debounced into the URL `q`).
  const [searchInput, setSearchInput] = useState(q);
  useEffect(() => setSearchInput(q), [q]);

  // ---- URL helpers ---------------------------------------------------------

  const setParams = useCallback(
    (patch: Record<string, string | null>, resetPage = true) => {
      const next = new URLSearchParams(searchParams.toString());
      for (const [k, v] of Object.entries(patch)) {
        if (v === null || v === "") next.delete(k);
        else next.set(k, v);
      }
      if (resetPage && !("page" in patch)) next.delete("page");
      const qs = next.toString();
      router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
    },
    [searchParams, router, pathname]
  );

  // Debounce the search input into the URL.
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const onSearchChange = (value: string) => {
    setSearchInput(value);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      setParams({ q: value || null });
    }, 250);
  };

  // ---- list header ---------------------------------------------------------

  useEffect(() => {
    let cancelled = false;
    adminShowList(listId)
      .then((res) => {
        if (!cancelled) setList(res.list);
      })
      .catch(() => {
        /* header is best-effort; the table below surfaces real errors */
      });
    return () => {
      cancelled = true;
    };
  }, [listId]);

  // ---- data ----------------------------------------------------------------

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    setErrorStatus(null);

    const run = async () => {
      try {
        if (serverDefault) {
          const res = await adminListSignups(listId, {
            status: status || undefined,
            limit: PER_PAGE,
            offset: (page - 1) * PER_PAGE,
          });
          if (cancelled) return;
          setRows(res.signups);
          setTotal(res.pagination.total);
        } else {
          // q / non-default sort ⇒ fetch all (bounded) and process client-side.
          const all = await adminFetchAllSignups(listId, { status: status || undefined });
          if (cancelled) return;
          const needle = q.trim().toLowerCase();
          const filtered = needle
            ? all.filter((s) => {
                if (s.email.toLowerCase().includes(needle)) return true;
                return Object.entries(s.attribs ?? {}).some(
                  ([k, v]) => k !== "listmonk" && attrValueString(v).toLowerCase().includes(needle)
                );
              })
            : all;
          const sorted = [...filtered].sort((a, b) => {
            let cmp = 0;
            if (sort === "email") cmp = a.email.localeCompare(b.email);
            else if (sort === "status") cmp = a.status.localeCompare(b.status);
            else cmp = a.inserted_at.localeCompare(b.inserted_at);
            return order === "asc" ? cmp : -cmp;
          });
          setTotal(sorted.length);
          setRows(sorted.slice((page - 1) * PER_PAGE, page * PER_PAGE));
        }
      } catch (e) {
        if (cancelled) return;
        const status2 = e instanceof AdminApiError ? e.status : null;
        setErrorStatus(status2);
        setError(e instanceof Error ? e.message : "Failed to load signups");
        setRows([]);
        setTotal(0);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    run();
    return () => {
      cancelled = true;
    };
  }, [listId, status, q, sort, order, page, serverDefault]);

  // Dynamic attribute columns derived from the rows currently in view.
  const attributeKeys = useMemo(() => collectAttributeKeys(rows), [rows]);

  const toggleSort = (key: SortKey) => {
    if (sort === key) {
      setParams({ sort: key, order: order === "asc" ? "desc" : "asc" });
    } else {
      setParams({ sort: key, order: key === "created_at" ? "desc" : "asc" });
    }
  };

  const sortCaret = (key: SortKey) => {
    if (sort !== key) return <span className="sg-data-table__sort-caret">↕</span>;
    return <span className="sg-data-table__sort-caret">{order === "asc" ? "↑" : "↓"}</span>;
  };
  const thClass = (key: SortKey) =>
    "sg-data-table__th--sortable" +
    (sort === key ? (order === "asc" ? " sg-data-table__th--asc" : " sg-data-table__th--desc") : "");

  const onExport = async () => {
    setExporting(true);
    try {
      const all = await adminFetchAllSignups(listId, { status: status || undefined });
      const needle = q.trim().toLowerCase();
      const filtered = needle
        ? all.filter((s) => {
            if (s.email.toLowerCase().includes(needle)) return true;
            return Object.entries(s.attribs ?? {}).some(
              ([k, v]) => k !== "listmonk" && attrValueString(v).toLowerCase().includes(needle)
            );
          })
        : all;
      const keys = collectAttributeKeys(filtered);
      const csv = signupsToCsv(filtered, keys);
      const parts = ["signups", list?.slug ?? listId];
      if (status) parts.push(`status=${status}`);
      parts.push(new Date().toISOString().slice(0, 10));
      downloadCsv(`${parts.join("-")}.csv`, csv);
    } catch {
      setError("Export failed — try again");
    } finally {
      setExporting(false);
    }
  };

  const servicesHref = `/app/admin/services/${projectId}`;
  const totalPages = Math.max(1, Math.ceil(total / PER_PAGE));

  if (error && errorStatus === 403) {
    return (
      <div>
        <BackLink href={servicesHref} label="Back to lists" />
        <ErrorPanel message="Access denied — you do not have permission to view this list's signups." />
      </div>
    );
  }
  if (error && errorStatus === 404) {
    return (
      <div>
        <BackLink href={servicesHref} label="Back to lists" />
        <EmptyState title="Not found" message="This list no longer exists." cta={{ href: servicesHref, label: "Back to lists" }} />
      </div>
    );
  }

  return (
    <div>
      <BackLink href={servicesHref} label="Back to lists" />

      <div className="sg-section-header">
        <div>
          <h1 className="sg-section-heading">{list?.name ?? "Signups"}</h1>
          {list ? (
            <p style={{ display: "flex", gap: "0.5rem", alignItems: "center", flexWrap: "wrap", margin: 0 }}>
              <Badge tone="neutral">{list.kind}</Badge>
              <OptInBadge mode={optInMode(list)} />
              {list.status === "archived" ? <Badge tone="muted">Archived</Badge> : null}
              <span className="sg-td-muted" style={{ fontSize: "0.8125rem" }}>{total} signup{total === 1 ? "" : "s"}</span>
            </p>
          ) : null}
        </div>
        <div className="sg-section-header__actions">
          <button
            className="sg-btn sg-btn--outline sg-btn--sm"
            onClick={onExport}
            disabled={exporting || (loading && rows.length === 0)}
          >
            {exporting ? "Exporting…" : "Export CSV"}
          </button>
        </div>
      </div>

      <div className="sg-toolbar">
        <input
          className="sg-search"
          type="search"
          placeholder="Search email or attribute value…"
          value={searchInput}
          onChange={(e) => onSearchChange(e.target.value)}
          aria-label="Search signups"
        />
        <select
          className="sg-toolbar__select"
          value={status}
          onChange={(e) => setParams({ status: e.target.value || null })}
          aria-label="Filter by status"
        >
          {STATUS_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      </div>

      {loading ? (
        <SkeletonRows count={8} />
      ) : rows.length === 0 ? (
        q || status ? (
          <EmptyState
            title="No signups match your filters"
            message="Try a different search term or status."
            cta={{ href: pathname, label: "Clear filters" }}
          />
        ) : (
          <EmptyState title="No signups yet" message="Signups to this list will appear here." />
        )
      ) : (
        <>
          <div className="sg-table--scroll">
            <table className="sg-table">
              <thead>
                <tr>
                  <th className={thClass("email")} onClick={() => toggleSort("email")}>
                    Email {sortCaret("email")}
                  </th>
                  <th className={thClass("status")} onClick={() => toggleSort("status")}>
                    Status {sortCaret("status")}
                  </th>
                  <th className={thClass("created_at")} onClick={() => toggleSort("created_at")}>
                    Created {sortCaret("created_at")}
                  </th>
                  {attributeKeys.map((k) => (
                    <th key={k}>{k}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((s) => (
                  <tr
                    key={s.id}
                    className={
                      "sg-row--clickable" + (s.status === "unsubscribed" ? " sg-row--muted" : "")
                    }
                    onClick={() => setSelected(s)}
                  >
                    <td>{s.email}</td>
                    <td>
                      <SignupStatusBadge status={s.status} />
                    </td>
                    <td>{formatDate(s.inserted_at)}</td>
                    {attributeKeys.map((k) => {
                      const raw = s.attribs?.[k];
                      const str = attrValueString(raw);
                      return (
                        <td key={k} className={str ? "sg-td-truncate" : "sg-td-muted"} title={str || undefined}>
                          {str || "—"}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="sg-pagination">
            <button
              className="sg-btn sg-btn--outline sg-btn--sm"
              disabled={page <= 1}
              onClick={() => setParams({ page: String(page - 1) }, false)}
            >
              Prev
            </button>
            <span className="sg-pagination__status">
              Page {page} of {totalPages}
            </span>
            <button
              className="sg-btn sg-btn--outline sg-btn--sm"
              disabled={page >= totalPages || rows.length < PER_PAGE}
              onClick={() => setParams({ page: String(page + 1) }, false)}
            >
              Next
            </button>
          </div>
        </>
      )}

      {selected ? (
        <SignupDetailPanel
          signup={selected}
          attributeKeys={attributeKeys}
          onClose={() => setSelected(null)}
        />
      ) : null}
    </div>
  );
}

export default function SignupsPage() {
  return (
    <Suspense fallback={<p className="sg-admin-loading">Loading…</p>}>
      <SignupsInner />
    </Suspense>
  );
}
