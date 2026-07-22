"use client";

import { useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { getApiBaseUrl, isMockMode } from "@/lib/api/config";
import { entriesApi, universesApi } from "@/lib/api";

export default function ExportPage() {
  const { universeId } = useParams() as { universeId: string };
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function download(format: "json" | "markdown") {
    setBusy(true);
    setError(null);
    try {
      if (isMockMode()) {
        const [{ universe }, { entries }] = await Promise.all([
          universesApi.get(universeId),
          entriesApi.list(universeId, { per_page: 100 }),
        ]);
        const payload = {
          universe,
          entries,
          exported_at: new Date().toISOString(),
        };
        const body =
          format === "json"
            ? JSON.stringify(payload, null, 2)
            : [
                `# ${universe.name}`,
                "",
                universe.description || "",
                "",
                ...entries.flatMap((e) => [
                  `## ${e.title}`,
                  `_${e.type} · ${e.status}_`,
                  "",
                  e.excerpt || "",
                  "",
                ]),
              ].join("\n");
        const blob = new Blob([body], {
          type: format === "json" ? "application/json" : "text/markdown",
        });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${universe.slug || universeId}.${format === "json" ? "json" : "md"}`;
        a.click();
        URL.revokeObjectURL(url);
      } else {
        const token = localStorage.getItem("access_token");
        const res = await fetch(
          `${getApiBaseUrl()}/api/v1/universes/${encodeURIComponent(universeId)}/export?format=${format}`,
          { headers: token ? { Authorization: `Bearer ${token}` } : {} },
        );
        if (!res.ok) throw new Error(`Export failed: ${res.status}`);
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${universeId}.${format === "json" ? "json" : "md"}`;
        a.click();
        URL.revokeObjectURL(url);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Export failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="max-w-lg mx-auto px-6 py-10">
      <Link
        href={`/${universeId}`}
        className="text-link text-[14px] hover:underline mb-6 inline-block"
      >
        ← Overview
      </Link>
      <h1 className="font-serif text-[28px] font-bold text-ink mb-2">Export</h1>
      <p className="font-sans text-[14px] text-ink-secondary mb-8">
        Download a universe bundle (entries + metadata). PDF ships later; Markdown
        and JSON are v0.1-critical.
      </p>

      <div className="flex flex-col sm:flex-row gap-3">
        <button
          type="button"
          disabled={busy}
          onClick={() => download("markdown")}
          className="rounded-lg bg-accent text-white px-5 py-2.5 text-[14px] disabled:opacity-60"
        >
          Export Markdown
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={() => download("json")}
          className="rounded-lg border border-rule px-5 py-2.5 text-[14px] disabled:opacity-60"
        >
          Export JSON
        </button>
      </div>
      {error && (
        <p className="mt-4 text-[13px] text-flag-warn bg-flag-warn-muted px-3 py-2 rounded-md">
          {error}
        </p>
      )}
    </div>
  );
}
