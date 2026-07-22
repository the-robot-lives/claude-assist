"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { NavBar } from "../navbar";
import { Footer } from "@/components/footer";
import { api, type DirectoryCategory } from "@/lib/api";
import { isAuthed } from "@/lib/session";

const inputClass =
  "w-full rounded-xl border-2 border-rule bg-surface px-4 py-3 font-ui text-base text-ink placeholder:text-ink-tertiary transition-all duration-200 focus:border-coral focus:shadow-[0_0_0_4px_rgba(232,112,74,0.1)] focus:outline-none disabled:opacity-50";
const labelClass =
  "font-ui text-xs font-bold uppercase tracking-[0.06em] text-ink-tertiary";

export default function SubmitPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [categories, setCategories] = useState<DirectoryCategory[]>([]);

  const [name, setName] = useState("");
  const [url, setUrl] = useState("");
  const [summary, setSummary] = useState("");
  const [categorySlug, setCategorySlug] = useState("");
  const [tags, setTags] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (!isAuthed()) {
      router.replace("/login?next=/submit");
      return;
    }
    setReady(true);
    api
      .directoryCategories()
      .then((r) => setCategories(r.categories))
      .catch(() => setCategories([]));
  }, [router]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !url.trim() || !summary.trim() || !categorySlug) {
      setError("Fill in the name, URL, summary, and category.");
      return;
    }
    setError("");
    setLoading(true);
    try {
      await api.submitSite({
        name: name.trim(),
        url: url.trim(),
        summary: summary.trim(),
        category_slug: categorySlug,
        tags: tags
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
      });
      setDone(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Submission failed. Try again.");
      setLoading(false);
    }
  }

  if (!ready) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream">
        <p className="font-mono text-[11px] uppercase tracking-[0.08em] text-ink-tertiary">
          Loading…
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-cream">
      <NavBar />

      <section className="px-6 py-12">
        <div className="mx-auto max-w-2xl">
          <p className="mb-6 font-ui text-xs font-bold uppercase tracking-[0.08em] text-olive">
            Submit a site
          </p>
          <h1
            className="font-display text-3xl font-semibold tracking-tight text-ink"
            style={{ fontVariationSettings: "'WONK' 1" }}
          >
            Suggest a site for the directory
          </h1>
          <p className="mt-3 max-w-[60ch] font-body text-base leading-relaxed text-ink-secondary">
            Every submission is read by a human editor and scored on five
            dimensions — originality, human authorship, depth, freshness, and
            design. Nothing is auto-published.{" "}
            <Link
              href="/about"
              className="font-ui font-semibold text-olive hover:text-olive-hover"
            >
              How scoring works &rarr;
            </Link>
          </p>

          {done ? (
            <div className="mt-8 rounded-2xl border-2 border-olive bg-olive-light px-6 py-6">
              <p className="font-display text-xl font-semibold text-olive" style={{ fontVariationSettings: "'WONK' 1" }}>
                Submission received.
              </p>
              <p className="mt-2 font-body text-sm leading-relaxed text-ink-secondary">
                An editor will review it and score it before it&apos;s listed. You can
                track its status any time.
              </p>
              <div className="mt-4 flex flex-wrap gap-4">
                <Link
                  href="/my-submissions"
                  className="rounded-xl bg-coral px-5 py-2 font-ui text-sm font-semibold text-white transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover"
                >
                  View my submissions
                </Link>
                <button
                  onClick={() => {
                    setName("");
                    setUrl("");
                    setSummary("");
                    setCategorySlug("");
                    setTags("");
                    setDone(false);
                  }}
                  className="font-ui text-sm font-semibold text-olive hover:text-olive-hover"
                >
                  Submit another
                </button>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-5">
              <div className="flex flex-col gap-1.5">
                <label htmlFor="name" className={labelClass}>
                  Site name
                </label>
                <input
                  id="name"
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Uses This"
                  required
                  disabled={loading}
                  className={inputClass}
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label htmlFor="url" className={labelClass}>
                  URL
                </label>
                <input
                  id="url"
                  type="url"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder="https://example.com"
                  required
                  disabled={loading}
                  className={inputClass}
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label htmlFor="summary" className={labelClass}>
                  Summary
                </label>
                <textarea
                  id="summary"
                  value={summary}
                  onChange={(e) => setSummary(e.target.value)}
                  placeholder="A sentence or two on what makes this site worth reading."
                  required
                  rows={4}
                  disabled={loading}
                  className={`${inputClass} resize-y`}
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label htmlFor="category" className={labelClass}>
                  Category
                </label>
                <select
                  id="category"
                  value={categorySlug}
                  onChange={(e) => setCategorySlug(e.target.value)}
                  required
                  disabled={loading}
                  className={inputClass}
                >
                  <option value="" disabled>
                    Choose a category…
                  </option>
                  {categories.map((cat) => (
                    <option key={cat.slug} value={cat.slug}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex flex-col gap-1.5">
                <label htmlFor="tags" className={labelClass}>
                  Tags <span className="font-normal normal-case text-ink-tertiary">(comma-separated, optional)</span>
                </label>
                <input
                  id="tags"
                  type="text"
                  value={tags}
                  onChange={(e) => setTags(e.target.value)}
                  placeholder="essays, personal, indie"
                  disabled={loading}
                  className={inputClass}
                />
              </div>

              {error && (
                <p className="font-ui text-sm text-error" role="alert">
                  {error}
                </p>
              )}

              <button
                type="submit"
                disabled={loading}
                className="self-start rounded-xl bg-coral px-6 py-3 font-ui text-base font-semibold text-white shadow-[0_2px_8px_rgba(232,112,74,0.2)] transition-all duration-150 hover:-translate-y-0.5 hover:bg-coral-hover disabled:opacity-50"
              >
                {loading ? "Submitting…" : "Submit for review"}
              </button>
            </form>
          )}
        </div>
      </section>

      <Footer />
    </div>
  );
}
