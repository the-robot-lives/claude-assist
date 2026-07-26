"use client";

// Wiki space view — custom two-pane page: a flat pages list for the space and a
// content pane for the selected page. Minimal stub (no page tree, no inline
// editor, no comments/attachments/reactions — polish comes later). Content
// renders as real markdown via MarkdownDoc (frontmatter block, headings,
// GFM, code fences, callouts, [[wikilinks]] resolved against `pages`).
import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type WikiPageDetail, type WikiPageSummary, type WikiSpace } from "@/lib/api";
import { useOrg } from "@/context/org";
import { Btn, Input, Textarea, Dialog, FieldLabel, Panel, PanelHeader, EmptyState } from "@/components/ui";
import { MarkdownDoc } from "@/components/wiki/MarkdownDoc";
import { cn } from "@/lib/cn";

function toSlug(title: string) {
  return title
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "")
    .replace(/^-+|-+$/g, "");
}

export default function WikiSpacePage() {
  const params = useParams<{ orgId: string; spaceId: string }>();
  const { currentOrg } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;
  const spaceId = params.spaceId;

  const [space, setSpace] = useState<WikiSpace | null>(null);
  const [pages, setPages] = useState<WikiPageSummary[]>([]);
  const [activePageId, setActivePageId] = useState<string | null>(null);
  const [page, setPage] = useState<WikiPageDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);

  const fetchSpace = useCallback(async () => {
    if (!orgId || !spaceId) return;
    setLoading(true);
    try {
      const res = await api.getWikiSpace(orgId, spaceId);
      setSpace(res.space);
      const list = res.pages ?? [];
      setPages(list);
      // Preserve the active selection if it still exists, else pick the first.
      setActivePageId((cur) => list.find((p) => p.id === cur)?.id ?? list[0]?.id ?? null);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load space");
    } finally {
      setLoading(false);
    }
  }, [orgId, spaceId]);

  useEffect(() => {
    fetchSpace();
  }, [fetchSpace]);

  // Load the selected page's full detail (content + embedded comments/etc.).
  useEffect(() => {
    if (!orgId || !activePageId) {
      setPage(null);
      return;
    }
    let live = true;
    api
      .getWikiPage(orgId, activePageId)
      .then((res) => live && setPage(res.page))
      .catch((err) => {
        if (!live) return;
        toast.error(err instanceof Error ? err.message : "Failed to load page");
        setPage(null);
      });
    return () => {
      live = false;
    };
  }, [orgId, activePageId]);

  if (loading) {
    return (
      <p className="px-[18px] py-6 text-[12px] text-faint" role="status">
        loading space…
      </p>
    );
  }

  return (
    <div className="app-content">
      <button
        type="button"
        className="justify-self-start text-[11px] text-faint hover:text-acc"
        onClick={() => router.push(`/app/${orgId}/wiki`)}
      >
        ← back to wiki
      </button>

      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">
            {(space?.name ?? "wiki space").toLowerCase()}
          </h1>
          {space?.description && (
            <p className="mt-1 font-prose text-[12.5px] text-mut">{space.description}</p>
          )}
        </div>
        <Btn variant="primary" onClick={() => setShowCreate(true)}>
          + new page
        </Btn>
      </header>

      <div className="grid gap-3.5 md:grid-cols-[212px_1fr]">
        {/* Pages list */}
        <Panel>
          <PanelHeader title="pages" />
          {pages.length === 0 ? (
            <p className="px-4 py-3 text-[12px] text-faint">no pages yet.</p>
          ) : (
            <div className="flex flex-col gap-0.5 p-2">
              {pages.map((p) => {
                const active = activePageId === p.id;
                return (
                  <button
                    key={p.id}
                    type="button"
                    className={cn(
                      "flex items-center gap-2 rounded-card px-2.5 py-1.5 text-left text-[12.5px]",
                      active ? "bg-acc-bg font-bold text-acc" : "text-mut hover:bg-sel hover:text-ink",
                    )}
                    onClick={() => setActivePageId(p.id)}
                  >
                    <span className="text-faint">·</span>
                    <span className="truncate">{p.title}</span>
                  </button>
                );
              })}
            </div>
          )}
        </Panel>

        {/* Selected page content */}
        <Panel>
          {!activePageId ? (
            <EmptyState title={pages.length === 0 ? "nothing to write yet" : "no page selected"}>
              {pages.length === 0 ? "create a page to start writing." : "select a page from the list."}
            </EmptyState>
          ) : !page ? (
            <p className="px-4 py-6 text-[12px] text-faint" role="status">
              loading page…
            </p>
          ) : (
            <>
              <PanelHeader
                title={page.title}
                sub="markdown · plain text"
                right={
                  page.updated_at ? `updated ${new Date(page.updated_at).toLocaleString()}` : undefined
                }
              />
              <div className="max-h-[36rem] overflow-auto p-4">
                {page.content ? (
                  <MarkdownDoc content={page.content} pages={pages} onNavigateToPage={setActivePageId} />
                ) : (
                  <p className="text-[12px] text-faint">(no content)</p>
                )}
              </div>
            </>
          )}
        </Panel>
      </div>

      {showCreate && orgId && spaceId && (
        <CreatePageDialog
          orgId={orgId}
          spaceId={spaceId}
          onClose={() => setShowCreate(false)}
          onSaved={(newId) => {
            setShowCreate(false);
            setActivePageId(newId);
            fetchSpace();
          }}
        />
      )}
    </div>
  );
}

function CreatePageDialog({
  orgId,
  spaceId,
  onClose,
  onSaved,
}: {
  orgId: string;
  spaceId: string;
  onClose: () => void;
  onSaved: (pageId: string) => void;
}) {
  const [title, setTitle] = useState("");
  const [slug, setSlug] = useState("");
  const [slugTouched, setSlugTouched] = useState(false);
  const [content, setContent] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    setSaving(true);
    setError(null);
    try {
      const res = await api.createWikiPage(orgId, spaceId, {
        title: title.trim(),
        slug: slug.trim() || toSlug(title),
        content: content || undefined,
      });
      toast.success("Page created");
      onSaved(res.page.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Request failed");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog
      open
      onClose={onClose}
      title="create page"
      footer={
        <>
          <Btn onClick={onClose}>cancel</Btn>
          <Btn variant="primary" type="submit" form="create-page-form" disabled={saving || !title.trim()}>
            {saving ? "creating…" : "create"}
          </Btn>
        </>
      }
    >
      <form id="create-page-form" onSubmit={submit} className="space-y-3">
        <FieldLabel label="title">
          <Input
            value={title}
            onChange={(e) => {
              setTitle(e.target.value);
              if (!slugTouched) setSlug(toSlug(e.target.value));
            }}
            placeholder="page title"
            autoFocus
          />
        </FieldLabel>
        <FieldLabel label="slug">
          <Input
            value={slug}
            onChange={(e) => {
              setSlugTouched(true);
              setSlug(e.target.value);
            }}
            placeholder="page-slug"
          />
        </FieldLabel>
        <FieldLabel label="content" hint="markdown · optional initial content">
          <Textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="# heading — body text…"
            rows={6}
          />
        </FieldLabel>
        {error && <p className="text-[12px] text-err">[ERR] {error}</p>}
      </form>
    </Dialog>
  );
}
