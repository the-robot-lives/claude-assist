"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { NavBar } from "../navbar";
import { Footer } from "@/components/footer";
import { api, type DirectoryCategory } from "@/lib/api";
import { isAuthed } from "@/lib/session";

export default function SubmitPage() {
  const [categories, setCategories] = useState<DirectoryCategory[]>([]);

  // Signed-in submitters get their suggestion attributed and can track it;
  // everyone else submits anonymously. Resolved in an effect so the server
  // render matches the first client render.
  const [authed, setAuthed] = useState(false);

  const [name, setName] = useState("");
  const [url, setUrl] = useState("");
  const [summary, setSummary] = useState("");
  const [categorySlug, setCategorySlug] = useState("");
  const [tags, setTags] = useState("");
  const [contactEmail, setContactEmail] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [done, setDone] = useState(false);

  useEffect(() => {
    setAuthed(isAuthed());
    api
      .directoryCategories()
      .then((r) => setCategories(r.categories))
      .catch(() => setCategories([]));
  }, []);

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
        ...(contactEmail.trim() ? { contact_email: contactEmail.trim() } : {}),
      });
      setDone(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Submission failed. Try again.");
      setLoading(false);
    }
  }

  function reset() {
    setName("");
    setUrl("");
    setSummary("");
    setCategorySlug("");
    setTags("");
    setDone(false);
    setLoading(false);
  }

  return (
    <div className="gc-page">
      <NavBar />

      <div className="gc-wrap">
        <div className="gc-form-page">
          <p className="gc-eyebrow">Submit a site</p>
          <h1 className="gc-form-title">Suggest a site for the directory</h1>
          <p className="gc-form-dek">
            Every suggestion is read by a human editor and scored on five
            dimensions — originality, human authorship, depth, freshness, and
            design. Nothing is auto-published.{" "}
            <Link href="/about">How scoring works &rarr;</Link>
          </p>
          <p className="gc-form-note">
            <b>No account needed</b> — a human reviews every suggestion. Leave an
            email if you&rsquo;d like to hear how it went.
          </p>

          {done ? (
            <div className="gc-form-done">
              <h2>Suggestion received.</h2>
              <p>
                An editor will read the site and score it before it&rsquo;s
                listed.{" "}
                {authed
                  ? "You can track its status any time."
                  : contactEmail.trim()
                    ? "We'll reach out at the address you left if there's anything to say."
                    : "Nothing else to do — thanks for the tip."}
              </p>
              <div className="gc-form-done-actions">
                {authed ? (
                  <Link className="gc-cta" href="/my-submissions">
                    View my submissions
                  </Link>
                ) : (
                  <Link className="gc-cta" href="/">
                    Back to the directory
                  </Link>
                )}
                <button className="gc-link" onClick={reset}>
                  Suggest another
                </button>
              </div>
            </div>
          ) : (
            <form className="gc-form" onSubmit={handleSubmit}>
              <div className="gc-field">
                <label className="gc-label" htmlFor="name">
                  Site name
                </label>
                <input
                  id="name"
                  className="gc-input"
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Uses This"
                  required
                  disabled={loading}
                />
              </div>

              <div className="gc-field">
                <label className="gc-label" htmlFor="url">
                  URL
                </label>
                <input
                  id="url"
                  className="gc-input"
                  type="url"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder="https://example.com"
                  required
                  disabled={loading}
                />
              </div>

              <div className="gc-field">
                <label className="gc-label" htmlFor="summary">
                  Summary
                </label>
                <textarea
                  id="summary"
                  className="gc-input"
                  value={summary}
                  onChange={(e) => setSummary(e.target.value)}
                  placeholder="A sentence or two on what makes this site worth reading."
                  required
                  rows={4}
                  disabled={loading}
                />
              </div>

              <div className="gc-field">
                <label className="gc-label" htmlFor="category">
                  Category
                </label>
                <select
                  id="category"
                  className="gc-input"
                  value={categorySlug}
                  onChange={(e) => setCategorySlug(e.target.value)}
                  required
                  disabled={loading}
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

              <div className="gc-field">
                <label className="gc-label" htmlFor="tags">
                  Tags <span>(optional)</span>
                </label>
                <input
                  id="tags"
                  className="gc-input"
                  type="text"
                  value={tags}
                  onChange={(e) => setTags(e.target.value)}
                  placeholder="essays, personal, indie"
                  disabled={loading}
                />
                <p className="gc-form-hint">Comma-separated.</p>
              </div>

              {!authed && (
                <div className="gc-field">
                  <label className="gc-label" htmlFor="contact_email">
                    Your email <span>(optional)</span>
                  </label>
                  <input
                    id="contact_email"
                    className="gc-input"
                    type="email"
                    value={contactEmail}
                    onChange={(e) => setContactEmail(e.target.value)}
                    placeholder="you@example.com"
                    disabled={loading}
                  />
                  <p className="gc-form-hint">
                    Only used to follow up on this suggestion. Skip it and stay
                    anonymous.
                  </p>
                </div>
              )}

              {error && (
                <p className="gc-form-error" role="alert">
                  {error}
                </p>
              )}

              <button className="gc-cta gc-cta-lg" type="submit" disabled={loading}>
                {loading ? "Submitting…" : "Submit for review"}
              </button>
            </form>
          )}
        </div>
      </div>

      <Footer />
    </div>
  );
}
