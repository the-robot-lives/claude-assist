"use client";

// Wiki spaces list — custom page (the wiki domain is a two-level browse model:
// spaces → pages, which doesn't fit the flat descriptor table). Lists spaces for
// the org with a create-space modal; a space opens the pages view.
import { useCallback, useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type WikiSpace } from "@/lib/api";
import { useOrg } from "@/context/org";
import { Button, Input, Textarea, Dialog } from "@/components/ui";

function toSlug(name: string) {
  return name
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "")
    .replace(/^-+|-+$/g, "");
}

export default function WikiSpacesPage() {
  const params = useParams<{ orgId: string }>();
  const { currentOrg, loading: orgLoading } = useOrg();
  const router = useRouter();
  const orgId = currentOrg?.id || params.orgId;

  const [spaces, setSpaces] = useState<WikiSpace[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);

  const fetchSpaces = useCallback(async () => {
    if (!orgId) return;
    setLoading(true);
    try {
      const res = await api.listWikiSpaces(orgId);
      setSpaces(res.spaces ?? []);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to load spaces");
    } finally {
      setLoading(false);
    }
  }, [orgId]);

  useEffect(() => {
    fetchSpaces();
  }, [fetchSpaces]);

  const scopeLabel = useMemo(
    () => currentOrg?.name || "Organization",
    [currentOrg?.name],
  );

  return (
    <div className="mx-auto max-w-5xl px-4 py-6">
      <header className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-text">Wiki</h1>
          <p className="text-sm text-text-secondary">{scopeLabel} · knowledge spaces</p>
        </div>
        <Button onClick={() => setShowCreate(true)}>+ New space</Button>
      </header>

      {orgLoading || !orgId ? (
        <p className="text-sm text-text-muted">{orgLoading ? "Loading…" : "Select an organization."}</p>
      ) : loading ? (
        <p className="text-sm text-text-muted" role="status">
          Loading spaces…
        </p>
      ) : spaces.length === 0 ? (
        <p className="text-sm text-text-muted">No spaces yet — create one to start writing.</p>
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2">
          {spaces.map((s) => (
            <li key={s.id}>
              <button
                type="button"
                className="w-full rounded-lg border border-border bg-surface p-4 text-left hover:bg-surface-alt"
                onClick={() => router.push(`/app/${orgId}/wiki/${s.id}`)}
              >
                <div className="flex items-baseline justify-between gap-2">
                  <h2 className="font-semibold text-text">{s.name}</h2>
                  <code className="text-xs text-text-muted">{s.slug}</code>
                </div>
                {s.description && (
                  <p className="mt-1 line-clamp-2 text-sm text-text-secondary">{s.description}</p>
                )}
                {s.updated_at && (
                  <p className="mt-2 text-xs text-text-muted">
                    Updated {new Date(s.updated_at).toLocaleDateString()}
                  </p>
                )}
              </button>
            </li>
          ))}
        </ul>
      )}

      {showCreate && orgId && (
        <CreateSpaceDialog
          orgId={orgId}
          onClose={() => setShowCreate(false)}
          onSaved={(space) => {
            setShowCreate(false);
            router.push(`/app/${orgId}/wiki/${space.id}`);
          }}
        />
      )}
    </div>
  );
}

function CreateSpaceDialog({
  orgId,
  onClose,
  onSaved,
}: {
  orgId: string;
  onClose: () => void;
  onSaved: (space: WikiSpace) => void;
}) {
  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [slugTouched, setSlugTouched] = useState(false);
  const [description, setDescription] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setSaving(true);
    setError(null);
    try {
      const res = await api.createWikiSpace(orgId, {
        name: name.trim(),
        slug: slug.trim() || toSlug(name),
        description: description.trim() || undefined,
      });
      toast.success("Space created");
      onSaved(res.space);
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
      title="Create space"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="create-space-form" disabled={saving || !name.trim()}>
            {saving ? "Creating…" : "Create"}
          </Button>
        </>
      }
    >
      <form id="create-space-form" onSubmit={submit} className="space-y-3">
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Name</span>
          <Input
            value={name}
            onChange={(e) => {
              setName(e.target.value);
              if (!slugTouched) setSlug(toSlug(e.target.value));
            }}
            placeholder="Engineering"
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
            placeholder="engineering"
          />
        </label>
        <label className="flex flex-col gap-1.5 text-sm">
          <span className="font-medium text-text">Description</span>
          <Textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Optional"
            rows={2}
          />
        </label>
        {error && <p className="text-sm text-error">{error}</p>}
      </form>
    </Dialog>
  );
}
