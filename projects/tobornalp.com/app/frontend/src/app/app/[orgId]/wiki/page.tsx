"use client";

// Wiki spaces list — custom page (the wiki domain is a two-level browse model:
// spaces → pages, which doesn't fit the flat descriptor table). Lists spaces for
// the org with a create-space modal; a space opens the pages view.
import { useCallback, useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { toast } from "sonner";
import { api, type WikiSpace } from "@/lib/api";
import { useOrg } from "@/context/org";
import { Btn, Input, Textarea, Dialog, FieldLabel, Key, EmptyState } from "@/components/ui";

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
    () => currentOrg?.name || "organization",
    [currentOrg?.name],
  );

  return (
    <div className="app-content">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-[13px] font-bold uppercase tracking-[0.1em] text-ink">wiki</h1>
          <p className="mt-1 text-[11px] text-mut">{scopeLabel.toLowerCase()} · knowledge spaces</p>
        </div>
        <Btn variant="primary" onClick={() => setShowCreate(true)}>
          + new space
        </Btn>
      </header>

      {orgLoading || !orgId ? (
        <p className="text-[12px] text-faint">{orgLoading ? "loading…" : "select an organization."}</p>
      ) : loading ? (
        <p className="text-[12px] text-faint" role="status">
          loading spaces…
        </p>
      ) : spaces.length === 0 ? (
        <EmptyState title="no spaces yet" icon={<span className="text-2xl">✎</span>}>
          create one to start writing.
        </EmptyState>
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2">
          {spaces.map((s) => (
            <li key={s.id}>
              <button
                type="button"
                className="w-full rounded-card border border-line2 bg-panel2 p-4 text-left transition-colors hover:border-faint hover:bg-sel"
                onClick={() => router.push(`/app/${orgId}/wiki/${s.id}`)}
              >
                <div className="flex items-baseline justify-between gap-2">
                  <h2 className="font-bold text-ink">{s.name}</h2>
                  <Key>{s.slug}</Key>
                </div>
                {s.description && (
                  <p className="mt-1 line-clamp-2 font-prose text-[12.5px] leading-relaxed text-mut">
                    {s.description}
                  </p>
                )}
                {s.updated_at && (
                  <p className="mt-2 text-[10.5px] text-faint">
                    updated {new Date(s.updated_at).toLocaleDateString()}
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
      title="create space"
      footer={
        <>
          <Btn onClick={onClose}>cancel</Btn>
          <Btn variant="primary" type="submit" form="create-space-form" disabled={saving || !name.trim()}>
            {saving ? "creating…" : "create"}
          </Btn>
        </>
      }
    >
      <form id="create-space-form" onSubmit={submit} className="space-y-3">
        <FieldLabel label="name">
          <Input
            value={name}
            onChange={(e) => {
              setName(e.target.value);
              if (!slugTouched) setSlug(toSlug(e.target.value));
            }}
            placeholder="engineering"
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
            placeholder="engineering"
          />
        </FieldLabel>
        <FieldLabel label="description">
          <Textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="optional"
            rows={2}
          />
        </FieldLabel>
        {error && <p className="text-[12px] text-err">[ERR] {error}</p>}
      </form>
    </Dialog>
  );
}
