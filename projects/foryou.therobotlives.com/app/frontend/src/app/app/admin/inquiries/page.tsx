"use client";

import { Suspense, useCallback, useEffect, useRef, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  AdminApiError,
  adminListInquiries,
  type AdminInquiry,
} from "@/components/admin/admin-fetch";
import { Badge, EmptyState, ErrorPanel, SkeletonRows } from "@/components/admin/ui";

const PER_PAGE = 50;
const STATUS_OPTIONS = [
  { value: "", label: "All statuses" },
  { value: "new", label: "New" },
  { value: "reviewed", label: "Reviewed" },
  { value: "closed", label: "Closed" },
  { value: "spam", label: "Spam" },
];

const STATUS_TONE: Record<string, "success" | "warning" | "danger" | "muted" | "neutral"> = {
  new: "warning",
  reviewed: "success",
  closed: "muted",
  spam: "danger",
};

function formatDate(iso?: string): string {
  if (!iso) return "—";
  const d = new Date(iso);
  return isNaN(d.getTime()) ? iso : d.toLocaleString();
}

function InquiryDetail({ inquiry, onClose }: { inquiry: AdminInquiry; onClose: () => void }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const metadata = inquiry.metadata && typeof inquiry.metadata === "object" ? inquiry.metadata : null;
  const metaEntries = metadata ? Object.entries(metadata) : [];

  return (
    <>
      <div className="sg-detail-overlay" onClick={onClose} aria-hidden="true" />
      <aside className="sg-detail-panel" role="dialog" aria-modal="true" aria-label="Inquiry detail">
        <div className="sg-detail-panel__header">
          <h2 className="sg-detail-panel__title">{inquiry.name || inquiry.email}</h2>
          <button className="sg-detail-panel__close" onClick={onClose} aria-label="Close detail">
            &times;
          </button>
        </div>
        <dl className="sg-detail-list">
          <dt>Email</dt>
          <dd>{inquiry.email}</dd>
          <dt>Status</dt>
          <dd>
            <Badge tone={STATUS_TONE[inquiry.status] ?? "neutral"}>{inquiry.status}</Badge>
          </dd>
          <dt>Source</dt>
          <dd>{inquiry.source || "—"}</dd>
          {inquiry.page_url ? (
            <>
              <dt>Page</dt>
              <dd>{inquiry.page_url}</dd>
            </>
          ) : null}
          <dt>Received</dt>
          <dd>{formatDate(inquiry.inserted_at || inquiry.created_at)}</dd>
        </dl>

        {inquiry.message ? (
          <>
            <p className="sg-detail-section-title">Message</p>
            <p style={{ fontSize: "0.875rem", whiteSpace: "pre-wrap", margin: 0 }}>{inquiry.message}</p>
          </>
        ) : null}

        {metaEntries.length > 0 ? (
          <>
            <p className="sg-detail-section-title">Metadata</p>
            <dl className="sg-detail-list">
              {metaEntries.map(([k, v]) => (
                <div key={k} style={{ display: "contents" }}>
                  <dt>{k}</dt>
                  <dd>{typeof v === "object" ? JSON.stringify(v) : String(v)}</dd>
                </div>
              ))}
            </dl>
          </>
        ) : null}
      </aside>
    </>
  );
}

function InquiriesInner() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const q = searchParams.get("q") ?? "";
  const status = searchParams.get("status") ?? "";
  const page = Math.max(1, parseInt(searchParams.get("page") ?? "1", 10) || 1);

  const [rows, setRows] = useState<AdminInquiry[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [unavailable, setUnavailable] = useState(false);
  const [selected, setSelected] = useState<AdminInquiry | null>(null);
  const [searchInput, setSearchInput] = useState(q);
  useEffect(() => setSearchInput(q), [q]);

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

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const onSearchChange = (value: string) => {
    setSearchInput(value);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => setParams({ q: value || null }), 250);
  };

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    setUnavailable(false);

    adminListInquiries({ q, status: status || undefined, page, per_page: PER_PAGE })
      .then((res) => {
        if (cancelled) return;
        setRows(res.inquiries);
        setTotal(res.total);
      })
      .catch((e) => {
        if (cancelled) return;
        // No admin-inquiries surface shipped yet ⇒ degrade gracefully.
        if (e instanceof AdminApiError && (e.status === 404 || e.status === 405)) {
          setUnavailable(true);
        } else {
          setError(e instanceof Error ? e.message : "Failed to load inquiries");
        }
        setRows([]);
        setTotal(0);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [q, status, page]);

  const totalPages = Math.max(1, Math.ceil(total / PER_PAGE));

  return (
    <div>
      <h1 className="sg-section-heading">Inquiries</h1>

      {unavailable ? (
        <>
          <p className="sg-notice">
            The admin inquiries surface is not wired to the backend yet. Inquiries submitted through
            site contact forms are captured, but the read endpoint (a Chunk B/F fast-follow) is
            pending. This page will populate automatically once it ships.
          </p>
          <EmptyState title="Inquiries review coming soon" message="No admin read endpoint is available yet." />
        </>
      ) : (
        <>
          <div className="sg-toolbar">
            <input
              className="sg-search"
              type="search"
              placeholder="Search name, email, message…"
              value={searchInput}
              onChange={(e) => onSearchChange(e.target.value)}
              aria-label="Search inquiries"
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
          ) : error ? (
            <ErrorPanel message={error} />
          ) : rows.length === 0 ? (
            q || status ? (
              <EmptyState title="No inquiries match your filters" cta={{ href: pathname, label: "Clear filters" }} />
            ) : (
              <EmptyState title="No inquiries yet" message="Inquiries submitted through your sites will appear here." />
            )
          ) : (
            <>
              <div className="sg-table--scroll">
                <table className="sg-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Email</th>
                      <th>Source</th>
                      <th>Status</th>
                      <th>Received</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((i) => (
                      <tr
                        key={i.id}
                        className={"sg-row--clickable" + (i.status === "spam" ? " sg-row--muted" : "")}
                        onClick={() => setSelected(i)}
                      >
                        <td>{i.name || "—"}</td>
                        <td>{i.email}</td>
                        <td className="sg-td-muted">{i.source || "—"}</td>
                        <td>
                          <Badge tone={STATUS_TONE[i.status] ?? "neutral"}>{i.status}</Badge>
                        </td>
                        <td>{formatDate(i.inserted_at || i.created_at)}</td>
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
        </>
      )}

      {selected ? <InquiryDetail inquiry={selected} onClose={() => setSelected(null)} /> : null}
    </div>
  );
}

export default function InquiriesPage() {
  return (
    <Suspense fallback={<p className="sg-admin-loading">Loading…</p>}>
      <InquiriesInner />
    </Suspense>
  );
}
