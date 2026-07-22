"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/context/auth";
import { api } from "@/lib/api";

const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export default function NewOrgPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [slug, setSlug] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!authLoading && !user) {
      router.push("/login");
    }
  }, [user, authLoading, router]);

  const slugInvalid = slug.length > 0 && !SLUG_PATTERN.test(slug);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");

    if (!SLUG_PATTERN.test(slug)) {
      setError("Slug must be lowercase letters, numbers, and single hyphens (e.g. my-org).");
      return;
    }

    setLoading(true);
    try {
      await api.createOrganization(slug, name);
      // Full reload so the org context re-fetches and the new org appears.
      window.location.href = "/app";
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to create organization");
      setLoading(false);
    }
  }

  if (authLoading) return <div>Loading...</div>;
  if (!user) return null;

  return (
    <div className="content">
      <main>
        <h1 className="sg-page-title">Create Organization</h1>
        <form onSubmit={handleSubmit} className="sg-form">
          {error && <p className="sg-error">{error}</p>}
          <div className="sg-field">
            <label htmlFor="org-name">Name</label>
            <input
              id="org-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              autoComplete="off"
            />
          </div>
          <div className="sg-field">
            <label htmlFor="org-slug">Slug</label>
            <input
              id="org-slug"
              type="text"
              value={slug}
              onChange={(e) => setSlug(e.target.value)}
              required
              autoComplete="off"
              pattern="[a-z0-9]+(?:-[a-z0-9]+)*"
              placeholder="my-org"
            />
            {slugInvalid && (
              <p className="sg-error">
                Use lowercase letters, numbers, and single hyphens.
              </p>
            )}
          </div>
          <button
            type="submit"
            className="sg-btn sg-btn--black"
            disabled={loading || slugInvalid}
          >
            {loading ? "Creating..." : "Create Organization"}
          </button>
          <p className="sg-form-note">
            <Link href="/app">Back to your organizations</Link>
          </p>
        </form>
      </main>
    </div>
  );
}
