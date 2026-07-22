"use client";

// Item-detail Links section. Shows outgoing (this → other) and incoming
// (other → this) item links, with an add form (link_type selector + target item)
// and per-row delete. Rendered below the descriptor detail view so the shared
// items descriptor stays untouched.
//
// API shape notes (gaps surfaced, not blocked):
//  - ItemLink only carries ids (no target/source title), so we fetch the org's
//    items once to resolve titles AND feed the target picker.
//  - listItems has no search/q param, so the target picker is a native Select of
//    all org items rather than a typeahead. Adequate for modest orgs; revisit
//    when a search endpoint lands.
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { toast } from "sonner";
import { api, type ItemLink } from "@/lib/api";
import { useApi, useMutation } from "@/lib/use-api";
import { Button, Select, SectionCard, Empty } from "@/components/ui";
import { LINK_TYPES, itemLabel } from "./util";

export interface LinksSectionProps {
  orgId: string;
  itemId: string;
}

export function LinksSection({ orgId, itemId }: LinksSectionProps) {
  // Org-wide item index: feeds BOTH the target picker and title resolution for
  // rendered links. Fetched once; non-fatal if it fails (picker degrades to ids).
  const itemsIdx = useApi(() => api.listItems(orgId).then((r) => r.items ?? []), [orgId]);
  const { data, loading, error, mutate } = useApi(
    () => api.listItemLinks(orgId, itemId),
    [orgId, itemId],
  );

  const [outgoing, setOutgoing] = useState<ItemLink[]>([]);
  const [incoming, setIncoming] = useState<ItemLink[]>([]);
  useEffect(() => {
    setOutgoing(data?.links.outgoing ?? []);
    setIncoming(data?.links.incoming ?? []);
  }, [data]);

  const itemById = useMemo(() => {
    const m = new Map<string, string>();
    for (const it of itemsIdx.data ?? []) m.set(it.id, itemLabel(it));
    return m;
  }, [itemsIdx.data]);

  const [linkType, setLinkType] = useState<string>(LINK_TYPES[0].value);
  const [targetId, setTargetId] = useState<string>("");

  const addMut = useMutation(
    (input: { target_item_id: string; link_type: string }) =>
      api.addItemLink(orgId, itemId, input),
    {
      optimistic: (input) => {
        const temp: ItemLink = {
          id: `temp-${Date.now()}`,
          link_type: input.link_type,
          target_item_id: input.target_item_id,
        };
        setOutgoing((prev) => [...prev, temp]);
      },
      revert: () => mutate(),
    },
  );

  const delMut = useMutation(
    (linkId: string) => api.deleteItemLink(orgId, linkId),
    {
      optimistic: (linkId) => {
        setOutgoing((prev) => prev.filter((l) => l.id !== linkId));
        setIncoming((prev) => prev.filter((l) => l.id !== linkId));
      },
      revert: () => mutate(),
    },
  );

  async function add(e: React.FormEvent) {
    e.preventDefault();
    if (!targetId) return;
    try {
      await addMut.trigger({ target_item_id: targetId, link_type: linkType });
      setTargetId("");
      mutate();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to add link");
    }
  }

  async function remove(linkId: string) {
    try {
      await delMut.trigger(linkId);
      mutate();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to remove link");
    }
  }

  const totalCount = outgoing.length + incoming.length;

  return (
    <SectionCard title="Links" count={totalCount}>
      <form onSubmit={add} className="mb-4 grid gap-2 sm:grid-cols-[10rem_1fr_auto] sm:items-end">
        <label className="flex flex-col gap-1 text-xs text-text-secondary">
          Link type
          <Select value={linkType} onChange={(e) => setLinkType(e.target.value)}>
            {LINK_TYPES.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </Select>
        </label>
        <label className="flex flex-col gap-1 text-xs text-text-secondary">
          Target item
          <Select value={targetId} onChange={(e) => setTargetId(e.target.value)} disabled={itemsIdx.loading}>
            <option value="">{itemsIdx.loading ? "Loading items…" : "Select an item"}</option>
            {(itemsIdx.data ?? [])
              .filter((it) => it.id !== itemId)
              .map((it) => (
                <option key={it.id} value={it.id}>
                  {itemLabel(it)}
                </option>
              ))}
          </Select>
        </label>
        <Button type="submit" size="sm" disabled={addMut.loading || !targetId}>
          {addMut.loading ? "Linking…" : "Add"}
        </Button>
      </form>

      {loading ? (
        <p className="py-4 text-center text-sm text-text-muted">Loading links…</p>
      ) : error ? (
        <p className="py-4 text-center text-sm text-error">{error.message}</p>
      ) : totalCount === 0 ? (
        <Empty>No linked items.</Empty>
      ) : (
        <div className="space-y-4">
          <LinkGroup
            title="Outgoing"
            rows={outgoing}
            dir="out"
            itemById={itemById}
            orgId={orgId}
            onDelete={remove}
            disabling={delMut.loading}
          />
          <LinkGroup
            title="Incoming"
            rows={incoming}
            dir="in"
            itemById={itemById}
            orgId={orgId}
            onDelete={remove}
            disabling={delMut.loading}
          />
        </div>
      )}
    </SectionCard>
  );
}

function LinkGroup({
  title,
  rows,
  dir,
  itemById,
  orgId,
  onDelete,
  disabling,
}: {
  title: string;
  rows: ItemLink[];
  dir: "out" | "in";
  itemById: Map<string, string>;
  orgId: string;
  onDelete: (id: string) => void;
  disabling: boolean;
}) {
  if (rows.length === 0) return null;
  return (
    <div>
      <h3 className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-text-muted">
        {title}
      </h3>
      <ul className="space-y-1.5">
        {rows.map((l) => {
          const otherId = dir === "out" ? l.target_item_id : l.source_item_id;
          const label = (otherId && itemById.get(otherId)) || (otherId ?? "—");
          return (
            <li
              key={l.id}
              className="flex items-center justify-between gap-2 rounded-md border border-border bg-surface-alt px-3 py-1.5 text-sm"
            >
              <div className="flex min-w-0 items-center gap-2">
                <span className="shrink-0 rounded bg-surface px-1.5 py-0.5 text-xs text-text-secondary">
                  {l.link_type}
                </span>
                {otherId ? (
                  <Link
                    href={`/app/${orgId}/items/${otherId}`}
                    className="truncate text-text hover:underline"
                    title={label}
                  >
                    {label}
                  </Link>
                ) : (
                  <span className="truncate text-text-muted">{label}</span>
                )}
              </div>
              <button
                type="button"
                className="shrink-0 rounded px-1.5 py-0.5 text-xs text-text-muted hover:bg-surface hover:text-error disabled:opacity-50"
                onClick={() => onDelete(l.id)}
                disabled={disabling}
              >
                Remove
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
