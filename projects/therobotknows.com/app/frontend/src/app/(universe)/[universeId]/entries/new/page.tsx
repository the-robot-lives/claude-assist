"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { entriesApi, ApiError } from "@/lib/api";
import { RichTextEditor } from "@/components/editor/rich-text-editor";
import { TagInput } from "@/components/tags/tag-input";
import { StatusControl } from "@/components/tags/status-control";
import { ENTRY_TYPES, ENTRY_TYPE_LABELS, type EntryStatus, type EntryType } from "@/lib/constants";

export default function NewEntryPage() {
  const { universeId } = useParams() as { universeId: string };
  const router = useRouter();
  const [type, setType] = useState<EntryType>("character");
  const [status, setStatus] = useState<EntryStatus>("draft");
  const [title, setTitle] = useState("");
  const [excerpt, setExcerpt] = useState("");
  const [body, setBody] = useState("");
  const [era, setEra] = useState("");
  const [region, setRegion] = useState("");
  const [tags, setTags] = useState<string[]>([]);
  const [templates, setTemplates] = useState<
    Record<string, { body_skeleton: string }>
  >({});
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    entriesApi.templates().then((res) => {
      const map: Record<string, { body_skeleton: string }> = {};
      for (const t of res.templates) map[t.type] = t;
      setTemplates(map);
    });
  }, []);

  function applyTemplate(t: EntryType) {
    setType(t);
    const sk = templates[t]?.body_skeleton;
    if (sk && !body.trim()) setBody(sk);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const { entry } = await entriesApi.create(universeId, {
        type,
        status,
        title,
        excerpt: excerpt || undefined,
        body,
        era: era || undefined,
        region: region || undefined,
        tag_names: tags,
      });
      router.push(`/${universeId}/entries/${entry.slug || entry.id}`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Create failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-3xl mx-auto px-6 py-10">
      <Link
        href={`/${universeId}/entries`}
        className="font-sans text-[14px] text-link hover:underline mb-6 inline-block"
      >
        ← Back to entries
      </Link>
      <h1 className="font-serif text-[28px] font-bold text-ink mb-6">
        New entry
      </h1>

      <form onSubmit={onSubmit} className="space-y-5">
        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
              Type
            </label>
            <select
              value={type}
              onChange={(e) => applyTemplate(e.target.value as EntryType)}
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px]"
            >
              {ENTRY_TYPES.map((t) => (
                <option key={t} value={t}>
                  {ENTRY_TYPE_LABELS[t]}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
              Status
            </label>
            <StatusControl value={status} onChange={setStatus} />
          </div>
        </div>

        <div>
          <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
            Title
          </label>
          <input
            required
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-serif text-[18px] focus:outline-none focus:border-accent"
          />
        </div>

        <div>
          <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
            Excerpt
          </label>
          <input
            value={excerpt}
            onChange={(e) => setExcerpt(e.target.value)}
            className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] focus:outline-none focus:border-accent"
          />
        </div>

        <RichTextEditor value={body} onChange={setBody} label="Body" />

        <div className="grid sm:grid-cols-2 gap-4">
          <div>
            <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
              Era
            </label>
            <input
              value={era}
              onChange={(e) => setEra(e.target.value)}
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px]"
            />
          </div>
          <div>
            <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
              Region
            </label>
            <input
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px]"
            />
          </div>
        </div>

        <div>
          <label className="block font-mono text-[11px] uppercase text-ink-tertiary mb-1.5">
            Tags
          </label>
          <TagInput value={tags} onChange={setTags} />
        </div>

        {error && (
          <p className="text-[13px] text-flag-warn bg-flag-warn-muted rounded-md px-3 py-2">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading || !title.trim()}
          className="rounded-lg bg-accent text-white font-sans text-[14px] font-medium px-6 py-2.5 disabled:opacity-60"
        >
          {loading ? "Creating…" : "Create entry"}
        </button>
      </form>
    </div>
  );
}
