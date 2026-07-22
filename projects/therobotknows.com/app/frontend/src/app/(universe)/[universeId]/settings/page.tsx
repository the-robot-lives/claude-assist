"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { universesApi, ApiError } from "@/lib/api";
import { Loader2 } from "lucide-react";

export default function UniverseSettingsPage() {
  const { universeId } = useParams() as { universeId: string };
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [genre, setGenre] = useState("");
  const [tone, setTone] = useState("");
  const [naming, setNaming] = useState("");
  const [constraints, setConstraints] = useState("");
  const [idOrSlug, setIdOrSlug] = useState(universeId);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { universe } = await universesApi.get(universeId);
        if (cancelled) return;
        setIdOrSlug(universe.slug || universe.id);
        setName(universe.name);
        setDescription(universe.description ?? "");
        setGenre(universe.genre ?? universe.config?.genre ?? "");
        setTone(universe.tone ?? universe.config?.tone ?? "");
        setNaming(String(universe.config?.naming_conventions ?? ""));
        const c = universe.config?.constraints;
        setConstraints(Array.isArray(c) ? c.join("\n") : "");
      } catch (e) {
        if (!cancelled)
          setError(e instanceof Error ? e.message : "Failed to load settings");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [universeId]);

  async function onSave(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      await universesApi.update(idOrSlug, {
        name,
        description,
        genre,
        tone,
        config: {
          genre,
          tone,
          naming_conventions: naming,
          constraints: constraints
            .split("\n")
            .map((s) => s.trim())
            .filter(Boolean),
        },
      });
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (
      !confirm(
        "Soft-delete this universe? It will disappear from your dashboard.",
      )
    )
      return;
    try {
      await universesApi.remove(idOrSlug);
      router.push("/app");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Delete failed");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 p-10 text-ink-secondary">
        <Loader2 className="animate-spin" size={16} /> Loading settings…
      </div>
    );
  }

  return (
    <div className="max-w-xl mx-auto px-6 py-10">
      <Link
        href={`/${universeId}`}
        className="font-sans text-[14px] text-link hover:underline mb-6 inline-block"
      >
        ← Back to overview
      </Link>
      <h1 className="font-serif text-[28px] font-bold text-ink mb-2">
        Universe settings
      </h1>
      <p className="font-sans text-[14px] text-ink-secondary mb-8">
        Genre and tone feed the generation pipeline later.
      </p>

      <form onSubmit={onSave} className="space-y-5">
        <Field label="Name">
          <input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
          />
        </Field>
        <Field label="Description">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={3}
            className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
          />
        </Field>
        <div className="grid sm:grid-cols-2 gap-4">
          <Field label="Genre">
            <input
              value={genre}
              onChange={(e) => setGenre(e.target.value)}
              className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
            />
          </Field>
          <Field label="Tone">
            <input
              value={tone}
              onChange={(e) => setTone(e.target.value)}
              className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
            />
          </Field>
        </div>
        <Field label="Naming conventions">
          <input
            value={naming}
            onChange={(e) => setNaming(e.target.value)}
            className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
          />
        </Field>
        <Field label="Constraints (one per line)">
          <textarea
            value={constraints}
            onChange={(e) => setConstraints(e.target.value)}
            rows={4}
            className="w-full rounded-lg border border-rule px-3 py-2.5 font-sans text-[14px]"
          />
        </Field>

        {error && (
          <p className="text-[13px] text-flag-warn bg-flag-warn-muted px-3 py-2 rounded-md">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={saving}
          className="rounded-lg bg-accent text-white px-5 py-2.5 text-[14px] disabled:opacity-60"
        >
          {saving ? "Saving…" : "Save settings"}
        </button>
      </form>

      <div className="mt-12 pt-8 border-t border-rule">
        <h2 className="font-mono text-[11px] uppercase text-flag-warn mb-2">
          Danger zone
        </h2>
        <button
          type="button"
          onClick={onDelete}
          className="rounded-lg border border-flag-warn text-flag-warn px-4 py-2 text-[14px]"
        >
          Delete universe
        </button>
      </div>
    </div>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
        {label}
      </label>
      {children}
    </div>
  );
}
