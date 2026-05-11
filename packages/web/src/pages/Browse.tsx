import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useConversations } from "../hooks/useApi.js";

type SortOption = "updated_at" | "started_at" | "message_count" | "title";

export function Browse() {
  const [sort, setSort] = useState<SortOption>("updated_at");
  const navigate = useNavigate();

  const { data, loading, error } = useConversations({ sort, limit: 100 });
  const conversations = data?.data ?? [];

  // Group by project
  const groups = new Map<string, typeof conversations>();
  for (const c of conversations) {
    const key = c.projectPath;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(c);
  }

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-medium text-text-bright">Browse</h1>
        <div className="flex items-center gap-2">
          <span className="text-xs text-text-dim">Sort:</span>
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value as SortOption)}
            className="rounded-md border border-border-subtle bg-surface px-2 py-1 text-xs text-text-primary outline-none"
          >
            <option value="updated_at">Last Updated</option>
            <option value="started_at">Date Started</option>
            <option value="message_count">Message Count</option>
            <option value="title">Title</option>
          </select>
        </div>
      </div>

      {loading && <p className="text-sm text-text-muted">Loading conversations...</p>}

      {error && <p className="text-sm text-red-400">Error: {error}</p>}

      {!loading && conversations.length === 0 && (
        <p className="text-sm text-text-muted">
          No conversations indexed. Run <code className="text-glow">claude-assist index</code> to get started.
        </p>
      )}

      {[...groups.entries()].map(([project, convs]) => (
        <div key={project}>
          <div className="flex items-center gap-2 mb-2">
            <h2 className="text-sm font-medium text-glow">{shortProject(project)}</h2>
            <span className="text-xs text-text-dim">({convs.length})</span>
          </div>
          <div className="space-y-1 mb-6">
            {convs.map((c) => (
              <button
                key={c.id}
                onClick={() => navigate(`/thread/${c.id}`)}
                className="flex w-full items-center gap-3 rounded-md px-3 py-2 text-left hover:bg-surface-active transition-colors"
              >
                <span className="font-mono text-xs text-text-dim">{c.id.slice(0, 8)}</span>
                <span className="flex-1 truncate text-sm text-text-primary">{c.title}</span>
                <span className="text-xs text-text-dim">{c.messageCount} msgs</span>
                <span className="text-xs text-text-dim">{new Date(c.updatedAt).toLocaleDateString()}</span>
                {c.status !== "active" && (
                  <span className="rounded-full bg-surface-active px-2 py-0.5 text-xs text-text-dim">{c.status}</span>
                )}
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function shortProject(path: string): string {
  const parts = path.split("/").filter(Boolean);
  return parts.length > 2 ? parts.slice(-2).join("/") : path;
}
