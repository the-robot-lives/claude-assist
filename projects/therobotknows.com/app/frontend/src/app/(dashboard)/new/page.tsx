"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { universesApi } from "@/lib/api";
import { ApiError } from "@/lib/api";

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
        config: {
          genre: genre || undefined,
          tone: tone || undefined,
        },
      });
      router.push(`/${universe.slug || universe.id}`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create universe");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-xl mx-auto py-8">
      <Link
        href="/"
        className="inline-flex items-center gap-2 font-sans text-[14px] text-link hover:text-link-hover transition-colors duration-200 mb-8"
      >
        <ArrowLeft size={14} strokeWidth={2} />
        Back to Universes
      </Link>

      <h1 className="font-serif text-[28px] font-bold text-ink mb-2">
        Create a New Universe
      </h1>
      <p className="font-sans text-[15px] text-ink-secondary leading-relaxed mb-8">
        Name your world, choose a genre, and start building. The knowledge graph,
        consistency engine, and AI generator activate as soon as you add your
        first entry.
      </p>

      <form onSubmit={onSubmit} className="space-y-5">
        <div>
          <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
            Name
          </label>
          <input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="The Ashward Chronicles"
            className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
          />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
              Genre
            </label>
            <input
              value={genre}
              onChange={(e) => setGenre(e.target.value)}
              placeholder="Dark Fantasy"
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
            />
          </div>
          <div>
            <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
              Tone
            </label>
            <input
              value={tone}
              onChange={(e) => setTone(e.target.value)}
              placeholder="grim, lyrical"
              className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent"
            />
          </div>
        </div>
        <div>
          <label className="block font-mono text-[11px] uppercase tracking-wide text-ink-tertiary mb-1.5">
            Description
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
            placeholder="A short summary of this creative universe…"
            className="w-full rounded-lg border border-rule bg-surface px-3 py-2.5 font-sans text-[14px] text-ink focus:outline-none focus:border-accent resize-y"
          />
        </div>

        {error && (
          <p className="font-sans text-[13px] text-flag-warn bg-flag-warn-muted rounded-md px-3 py-2">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading || !name.trim()}
          className="w-full sm:w-auto rounded-lg bg-accent text-white font-sans text-[14px] font-medium px-6 py-2.5 hover:opacity-90 disabled:opacity-60"
        >
          {loading ? "Creating…" : "Create universe"}
        </button>
      </form>
    </div>
  );
}
