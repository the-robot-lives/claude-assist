"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { universesApi, ApiError } from "@/lib/api";

export default function NewUniversePage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [genre, setGenre] = useState("");
  const [tone, setTone] = useState("");
  const [description, setDescription] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const { universe } = await universesApi.create({
        name,
        genre: genre || undefined,
        tone: tone || undefined,
        description: description || undefined,
        config: { genre: genre || undefined, tone: tone || undefined },
      });
      router.push(`/${universe.slug || universe.id}`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create universe");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-xl py-2">
      <Link
        href="/app"
        className="mb-8 inline-flex items-center gap-2 font-sans text-[14px] text-link hover:text-link-hover"
      >
        <ArrowLeft size={14} strokeWidth={2} />
        Back to universes
      </Link>
      <h1 className="mb-2 font-serif text-[28px] font-bold text-ink">
        Create a universe
      </h1>
      <p className="mb-8 font-sans text-[15px] leading-relaxed text-ink-secondary">
        Name your world, set genre and tone, then start building canon.
      </p>
      <form onSubmit={onSubmit} className="space-y-5">
        <Field label="Name">
          <input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="The Ashward Chronicles"
            className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
          />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Genre">
            <input
              value={genre}
              onChange={(e) => setGenre(e.target.value)}
              placeholder="Dark Fantasy"
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
            />
          </Field>
          <Field label="Tone">
            <input
              value={tone}
              onChange={(e) => setTone(e.target.value)}
              placeholder="grim, lyrical"
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
            />
          </Field>
        </div>
        <Field label="Description">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
            className="w-full resize-y rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] focus:border-accent focus:outline-none"
          />
        </Field>
        {error && (
          <p className="rounded-md bg-flag-warn-muted px-3 py-2 font-sans text-[13px] text-flag-warn">
            {error}
          </p>
        )}
        <button
          type="submit"
          disabled={loading || !name.trim()}
          className="rounded-lg bg-accent px-6 py-2.5 font-sans text-[14px] font-medium text-white disabled:opacity-60"
        >
          {loading ? "Creating…" : "Create universe"}
        </button>
      </form>
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
      <label className="mb-1.5 block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary">
        {label}
      </label>
      {children}
    </div>
  );
}
