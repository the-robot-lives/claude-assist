"use client";

// Wiki space view — custom two-pane page: a flat pages list for the space and a
// content pane for the selected page. Minimal stub (no page tree, no inline
// editor, no comments/attachments/reactions — polish comes later). Content is
// rendered in a <pre>; tobornalp has no Markdown component.
import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type WikiPageDetail, type WikiPageSummary, type WikiSpace } from "@/lib/api";
import { useOrg } from "@/context/org";
import { Button, Input, Textarea, Dialog } from "@/components/ui";

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
      <p className="px-4 py-6 text-sm text-text-muted" role="status">
        Loading space…
      </p>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-6">
      <button
        type="button"
        className="mb-3 text-xs text-text-muted hover:text-text hover:underline"
        onClick={() => router.push(`/app/${orgId}/wiki`)}
      >
        ← Back to wiki
      </button>

      <header className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">{space?.name ?? "Wiki space"}</h1>
          {space?.description && (
            <p className="text-sm text-text-secondary">{space.description}</p>
          )}
        </div>
        <Button onClick={() => setShowCreate(true)}>+ New page</Button>
      </header>

      <div className="grid gap-6 md:grid-cols-[15rem_1fr]">
        {/* Pages list */}
        <aside className="overflow-hidden rounded-lg border border-border bg-surface">
          <div className="border-b border-border bg-surface-alt px-3 py-2 text-sm font-medium text-text">
            Pages
          </div>
          {pages.length === 0 ? (
            <p className="px-3 py-3 text-sm text-text-muted">No pages yet.</p>
          ) : (
            <ul className="divide-y divide-border">
              {pages.map((p) => (
                <li key={p.id}>
                  <button
                    type="button"
                    className={`block w-full px-3 py-2 text-left text-sm hover:bg-surface-alt ${
                      activePageId === p.id ? "bg-surface-alt font-medium text-text" : "text-text"
                    }`}
                    onClick={() => setActivePageId(p.id)}
                  >
                    {p.title}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </aside>

        {/* Selected page content */}
        <section className="overflow-hidden rounded-lg border border-border bg-surface">
          {!activePageId ? (
            <p className="px-4 py-6 text-sm text-text-muted">
              {pages.length === 0
                ? "Create a page to start writing."
                : "Select a page from the list."}
            </p>
          ) : !page ? (
            <p className="px-4 py-6 text-sm text-text-muted" role="status">
              Loading page…
            </p>
          ) : (
            <>
              <div className="border-b border-border bg-surface-alt px-4 py-2">
                <h2 className="text-lg font-semibold text-text">{page.title}</h2>
                {page.updated_at && (
                  <p className="text-xs text-text-muted">
                    Updated {new Date(page.updated_at).toLocaleString()}
                  </p>
                )}
              </div>
              <pre className="max-h-[36rem] overflow-auto whitespace-pre-wrap break-words p-4 text-sm text-text">
                {page.content || "(no content)"}
              </pre>
            </>
          )}
        </section>
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
      title="Create page"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="create-page-form" disabled={saving || !title.trim()}>
            {saving ? "Creating…" : "Create"}
          </Button>
        </>
      }
    >
      <form id="create-page-form" onSubmit={submit} className="space-y-3">
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Title</span>
          <Input
            value={title}
            onChange={(e) => {
              setTitle(e.target.value);
              if (!slugTouched) setSlug(toSlug(e.target.value));
            }}
            placeholder="Page title"
            autoFocus
          />
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Slug</span>
          <Input
            value={slug}
            onChange={(e) => {
              setSlugTouched(true);
              setSlug(e.target.value);
            }}
            placeholder="page-slug"
          />
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Content</span>
          <Textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Optional initial content"
            rows={6}
          />
        </label>
        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}
