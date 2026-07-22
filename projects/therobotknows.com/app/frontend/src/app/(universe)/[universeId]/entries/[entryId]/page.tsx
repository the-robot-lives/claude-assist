"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { entriesApi, ApiError } from "@/lib/api";
import { toUiEntry } from "@/lib/api/mappers";
import { RichTextEditor, RichTextRenderer } from "@/components/editor/rich-text-editor";
import { TagInput } from "@/components/tags/tag-input";
import { StatusBadge, StatusControl } from "@/components/tags/status-control";
import { ENTRY_TYPE_LABELS, type EntryStatus, type EntryType } from "@/lib/constants";
import { Loader2 } from "lucide-react";

export default function EntryDetailPage() {
  const { universeId, entryId } = useParams() as {
    universeId: string;
    entryId: string;
  };
  const router = useRouter();
  const [apiId, setApiId] = useState<string | null>(null);
  const [editing, setEditing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [type, setType] = useState<EntryType>("character");
  const [status, setStatus] = useState<EntryStatus>("draft");
  const [title, setTitle] = useState("");
  const [excerpt, setExcerpt] = useState("");
  const [body, setBody] = useState("");
  const [era, setEra] = useState("");
  const [region, setRegion] = useState("");
  const [tags, setTags] = useState<string[]>([]);
  const [version, setVersion] = useState(1);
  const [updatedAt, setUpdatedAt] = useState("");

  async function load() {
    setLoading(true);
    try {
      const { entry } = await entriesApi.get(universeId, entryId);
      const ui = toUiEntry(entry);
      setApiId(entry.id);
      setType(entry.type);
      setStatus(entry.status);
      setTitle(entry.title);
      setExcerpt(entry.excerpt ?? "");
      setBody(ui.body);
      setEra(entry.era ?? "");
      setRegion(entry.region ?? "");
      setTags((entry.tags ?? []).map((t) => t.name));
      setVersion(entry.version ?? 1);
      setUpdatedAt(entry.updated_at);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load entry");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [universeId, entryId]);

  async function onSave(e: FormEvent) {
    e.preventDefault();
    if (!apiId) return;
    setSaving(true);
    setError(null);
    try {
      const { entry } = await entriesApi.update(universeId, apiId, {
        type,
        title,
        excerpt,
        body,
        era: era || undefined,
        region: region || undefined,
        tag_names: tags,
      });
      if (entry.status !== status) {
        await entriesApi.setStatus(universeId, apiId, status);
      }
      setEditing(false);
      await load();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!apiId) return;
    if (!confirm("Delete this entry? This soft-deletes the record.")) return;
    try {
      await entriesApi.remove(universeId, apiId);
      router.push(`/${universeId}/entries`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Delete failed");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 p-10 text-ink-secondary">
        <Loader2 className="animate-spin" size={16} /> Loading entry…
      </div>
    );
  }

  if (error && !title) {
    return (
      <div className="p-10">
        <p className="text-flag-warn mb-4">{error}</p>
        <Link href={`/${universeId}/entries`} className="text-accent">
          ← Back to entries
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto px-6 py-10">
      <div className="flex items-center justify-between gap-4 mb-6 flex-wrap">
        <Link
          href={`/${universeId}/entries`}
          className="font-sans text-[14px] text-link hover:underline"
        >
          ← Entries
        </Link>
        <div className="flex gap-2">
          {!editing && (
            <>
              <Link
                href={`/${universeId}/entries/${entryId}/history`}
                className="font-mono text-[11px] uppercase tracking-wide px-3 py-1.5 border border-rule rounded-lg hover:border-accent"
              >
                History
              </Link>
              <button
                type="button"
                onClick={() => setEditing(true)}
                className="font-mono text-[11px] uppercase tracking-wide px-3 py-1.5 border border-rule rounded-lg hover:border-accent"
              >
                Edit
              </button>
            </>
          )}
          <button
            type="button"
            onClick={onDelete}
            className="font-mono text-[11px] uppercase tracking-wide px-3 py-1.5 border border-flag-warn text-flag-warn rounded-lg"
          >
            Delete
          </button>
        </div>
      </div>

      {editing ? (
        <form onSubmit={onSave} className="space-y-5">
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full font-serif text-[28px] font-bold bg-transparent border-b border-rule focus:outline-none focus:border-accent pb-2"
          />
          <StatusControl value={status} onChange={setStatus} />
          <input
            value={excerpt}
            onChange={(e) => setExcerpt(e.target.value)}
            placeholder="Excerpt"
            className="w-full rounded-lg border border-rule px-3 py-2 font-sans text-[14px]"
          />
          <RichTextEditor value={body} onChange={setBody} />
          <div className="grid sm:grid-cols-2 gap-4">
            <input
              value={era}
              onChange={(e) => setEra(e.target.value)}
              placeholder="Era"
              className="rounded-lg border border-rule px-3 py-2 font-sans text-[14px]"
            />
            <input
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              placeholder="Region"
              className="rounded-lg border border-rule px-3 py-2 font-sans text-[14px]"
            />
          </div>
          <TagInput value={tags} onChange={setTags} />
          {error && (
            <p className="text-[13px] text-flag-warn bg-flag-warn-muted px-3 py-2 rounded-md">
              {error}
            </p>
          )}
          <div className="flex gap-3">
            <button
              type="submit"
              disabled={saving}
              className="rounded-lg bg-accent text-white px-5 py-2 text-[14px] disabled:opacity-60"
            >
              {saving ? "Saving…" : "Save"}
            </button>
            <button
              type="button"
              onClick={() => {
                setEditing(false);
                load();
              }}
              className="rounded-lg border border-rule px-5 py-2 text-[14px]"
            >
              Cancel
            </button>
          </div>
        </form>
      ) : (
        <article>
          <div className="flex items-center gap-3 mb-3 flex-wrap">
            <span className="font-mono text-[11px] uppercase tracking-[0.06em] text-ink-tertiary">
              {ENTRY_TYPE_LABELS[type]}
            </span>
            <StatusBadge status={status} />
            <span className="font-mono text-[11px] text-ink-tertiary">
              v{version}
            </span>
          </div>
          <h1 className="font-serif text-[32px] font-bold text-ink mb-3">
            {title}
          </h1>
          {excerpt && (
            <p className="font-sans text-[16px] text-ink-secondary mb-6 leading-relaxed">
              {excerpt}
            </p>
          )}
          <RichTextRenderer value={body} className="mb-8" />
          <div className="flex flex-wrap gap-2 mb-4">
            {tags.map((t) => (
              <span
                key={t}
                className="font-mono text-[12px] bg-elevated text-ink-tertiary px-2 py-0.5 rounded-sm"
              >
                {t}
              </span>
            ))}
          </div>
          <p className="font-mono text-[11px] text-ink-tertiary">
            {[era, region].filter(Boolean).join(" · ")}
            {updatedAt ? ` · Updated ${new Date(updatedAt).toLocaleString()}` : ""}
          </p>
        </article>
      )}
    </div>
  );
}
