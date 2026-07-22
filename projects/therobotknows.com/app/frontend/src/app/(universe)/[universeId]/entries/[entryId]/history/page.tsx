"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { isMockMode } from "@/lib/api/config";
import { request } from "@/lib/api";

interface VersionRow {
  id: string;
  version: number;
  reason: string;
  inserted_at?: string;
}

export default function EntryHistoryPage() {
  const { universeId, entryId } = useParams() as {
    universeId: string;
    entryId: string;
  };
  const [versions, setVersions] = useState<VersionRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (isMockMode()) {
      setVersions([
        {
          id: "1",
          version: 2,
          reason: "update",
          inserted_at: new Date().toISOString(),
        },
        {
          id: "2",
          version: 1,
          reason: "create",
          inserted_at: new Date(Date.now() - 86400000).toISOString(),
        },
      ]);
      return;
    }
    request<{ versions: VersionRow[] }>(
      `/api/v1/universes/${encodeURIComponent(universeId)}/entries/${encodeURIComponent(entryId)}/versions`,
    )
      .then((r) => setVersions(r.versions))
      .catch((e) => setError(e.message));
  }, [universeId, entryId]);

  async function restore(version: number) {
    if (isMockMode()) {
      setMessage(`Mock restore of v${version}`);
      return;
    }
    try {
      await request(
        `/api/v1/universes/${encodeURIComponent(universeId)}/entries/${encodeURIComponent(entryId)}/versions/${version}/restore`,
        { method: "POST" },
      );
      setMessage(`Restored version ${version}`);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Restore failed");
    }
  }

  return (
    <div className="max-w-xl mx-auto px-6 py-10">
      <Link
        href={`/${universeId}/entries/${entryId}`}
        className="text-link text-[14px] hover:underline mb-6 inline-block"
      >
        ← Entry
      </Link>
      <h1 className="font-serif text-[28px] font-bold text-ink mb-6">
        Version history
      </h1>
      {error && <p className="text-flag-warn mb-4 text-[13px]">{error}</p>}
      {message && (
        <p className="text-success mb-4 text-[13px] bg-success-muted px-3 py-2 rounded-md">
          {message}
        </p>
      )}
      <ul className="space-y-3">
        {versions.map((v) => (
          <li
            key={v.id}
            className="border border-rule rounded-lg px-4 py-3 flex items-center justify-between"
          >
            <div>
              <span className="font-mono text-[12px] text-ink">v{v.version}</span>
              <span className="font-mono text-[11px] text-ink-tertiary ml-2">
                {v.reason}
              </span>
              {v.inserted_at && (
                <p className="font-mono text-[10px] text-ink-tertiary mt-1">
                  {new Date(v.inserted_at).toLocaleString()}
                </p>
              )}
            </div>
            <button
              type="button"
              onClick={() => restore(v.version)}
              className="font-mono text-[11px] uppercase border border-rule rounded-lg px-3 py-1.5"
            >
              Restore
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
