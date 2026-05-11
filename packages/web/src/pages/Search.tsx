import React, { useState, useEffect } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useSearch } from "../hooks/useApi.js";

export function Search() {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  const initialQuery = searchParams.get("q") ?? "";
  const initialMode = (searchParams.get("mode") ?? "fts") as "fts" | "semantic";

  const [inputValue, setInputValue] = useState(initialQuery);
  const [query, setQuery] = useState(initialQuery);
  const [mode, setMode] = useState<"fts" | "semantic">(initialMode);

  const { data, loading, error } = useSearch(query, mode);
  const results = data?.data ?? [];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setQuery(inputValue);
    setSearchParams({ q: inputValue, mode });
  };

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <h1 className="text-xl font-medium text-text-bright">Search</h1>

      {/* Search bar */}
      <form onSubmit={handleSubmit} className="flex h-12 items-center rounded-md border border-border-subtle bg-surface px-4 focus-within:border-glow">
        <span className="mr-3 text-text-dim">{"⌕"}</span>
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          placeholder="Search conversations..."
          className="flex-1 bg-transparent text-sm text-text-primary placeholder:text-text-dim outline-none"
          autoFocus
        />
        <div className="flex gap-1">
          <button
            type="button"
            onClick={() => setMode("fts")}
            className={`rounded-full px-3 py-1 text-xs font-medium ${
              mode === "fts" ? "bg-glow text-void" : "bg-surface-active text-text-muted"
            }`}
          >
            Text
          </button>
          <button
            type="button"
            onClick={() => setMode("semantic")}
            className={`rounded-full px-3 py-1 text-xs font-medium ${
              mode === "semantic" ? "bg-glow text-void" : "bg-surface-active text-text-muted"
            }`}
          >
            Semantic
          </button>
        </div>
      </form>

      {/* Results */}
      {loading && query && (
        <p className="text-sm text-text-muted">Searching...</p>
      )}

      {error && (
        <p className="text-sm text-red-400">Error: {error}</p>
      )}

      {!loading && query && results.length === 0 && (
        <p className="text-sm text-text-muted">
          No results for "<span className="text-glow">{query}</span>". Try a different query.
        </p>
      )}

      {results.length > 0 && (
        <div className="space-y-3">
          <p className="text-sm text-text-dim">
            {results.length} result{results.length !== 1 ? "s" : ""} for "<span className="text-glow">{query}</span>"
          </p>
          {results.map((r, i) => (
            <button
              key={i}
              onClick={() => navigate(`/thread/${r.conversation.id}`)}
              className="block w-full rounded-md border border-border-subtle bg-surface p-4 text-left hover:border-glow/30 transition-colors"
            >
              <div className="flex items-center gap-2 mb-1">
                <span className="font-mono text-xs text-text-dim">{r.conversation.id.slice(0, 8)}</span>
                <span className="text-xs text-glow">[{shortProject(r.conversation.projectPath)}]</span>
                <span className="flex-1 truncate text-sm font-medium text-text-primary">{r.conversation.title}</span>
              </div>
              <p className="text-xs text-text-muted">{cleanSnippet(r.snippet)}</p>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function shortProject(path: string): string {
  const parts = path.split("/").filter(Boolean);
  return parts.length > 2 ? parts.slice(-2).join("/") : path;
}

function cleanSnippet(snippet: string): string {
  return snippet.replace(/<<</g, "").replace(/>>>/g, "");
}
