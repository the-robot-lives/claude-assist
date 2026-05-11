import React, { useState, useEffect } from "react";
import { apiFetch, useIndexStatus } from "../hooks/useApi.js";

interface AppConfig {
  indexPaths: string[];
  embedding: { provider: string; model?: string };
  server: { port: number; host: string };
}

export function Settings() {
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [reindexing, setReindexing] = useState(false);
  const [newPath, setNewPath] = useState("");
  const { data: idxData, refetch: refetchIndex } = useIndexStatus();
  const indexStatus = idxData?.data;

  useEffect(() => {
    apiFetch<{ data: AppConfig }>("/config")
      .then((res) => {
        setConfig(res.data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const handleSave = async () => {
    if (!config) return;
    setSaving(true);
    try {
      const res = await apiFetch<{ data: AppConfig }>("/config", {
        method: "PATCH",
        body: JSON.stringify(config),
      });
      setConfig(res.data);
    } catch {
      // Error handling would go here
    }
    setSaving(false);
  };

  const handleReindex = async () => {
    setReindexing(true);
    try {
      await apiFetch("/index/rebuild", { method: "POST" });
      setTimeout(() => {
        refetchIndex();
        setReindexing(false);
      }, 2000);
    } catch {
      setReindexing(false);
    }
  };

  const addPath = () => {
    if (!config || !newPath.trim()) return;
    setConfig({ ...config, indexPaths: [...config.indexPaths, newPath.trim()] });
    setNewPath("");
  };

  const removePath = (idx: number) => {
    if (!config) return;
    setConfig({ ...config, indexPaths: config.indexPaths.filter((_, i) => i !== idx) });
  };

  if (loading) {
    return <div className="mx-auto max-w-3xl"><p className="text-sm text-text-muted">Loading...</p></div>;
  }

  return (
    <div className="mx-auto max-w-3xl">
      <h1 className="mb-6 text-xl font-medium text-text-bright">Settings</h1>
      <div className="space-y-6">
        {/* Index Configuration */}
        <section className="rounded-md border border-border-subtle bg-surface p-6">
          <h2 className="mb-4 text-base font-medium text-text-primary">Index Configuration</h2>

          <div className="space-y-2 mb-4">
            {config?.indexPaths.map((path, i) => (
              <div key={i} className="flex items-center gap-2">
                <code className="flex-1 rounded bg-canvas px-3 py-1.5 text-xs text-text-muted">{path}</code>
                <button onClick={() => removePath(i)} className="text-xs text-red-400 hover:text-red-300">Remove</button>
              </div>
            ))}
          </div>

          <div className="flex gap-2 mb-4">
            <input
              type="text"
              value={newPath}
              onChange={(e) => setNewPath(e.target.value)}
              placeholder="Add watch path..."
              className="flex-1 rounded bg-canvas px-3 py-1.5 text-sm text-text-primary placeholder:text-text-dim outline-none border border-border-subtle"
            />
            <button onClick={addPath} className="rounded bg-surface-active px-3 py-1 text-xs text-text-muted hover:text-text-primary">
              Add
            </button>
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={handleReindex}
              disabled={reindexing}
              className="rounded bg-glow px-4 py-1.5 text-sm font-medium text-void hover:bg-glow/90 disabled:opacity-50"
            >
              {reindexing ? "Rebuilding..." : "Rebuild Index"}
            </button>
            <span className="text-xs text-text-dim">
              {indexStatus?.conversationCount ?? 0} conversations indexed
              {indexStatus?.lastIndexed && (
                <> | Last: {new Date(indexStatus.lastIndexed).toLocaleString()}</>
              )}
            </span>
          </div>
        </section>

        {/* Embedding Provider */}
        <section className="rounded-md border border-border-subtle bg-surface p-6">
          <h2 className="mb-4 text-base font-medium text-text-primary">Embedding Provider</h2>
          <select
            value={config?.embedding.provider ?? "local"}
            onChange={(e) => config && setConfig({ ...config, embedding: { ...config.embedding, provider: e.target.value } })}
            className="rounded bg-canvas px-3 py-1.5 text-sm text-text-primary border border-border-subtle outline-none"
          >
            <option value="local">Local (Transformers.js)</option>
            <option value="openai">OpenAI</option>
            <option value="voyage">Voyage</option>
            <option value="anthropic">Anthropic</option>
          </select>
          <p className="mt-2 text-xs text-text-dim">
            Local embeddings use all-MiniLM-L6-v2 (~25MB, runs on CPU). No API key required.
          </p>
        </section>

        {/* Save */}
        <div className="flex justify-end">
          <button
            onClick={handleSave}
            disabled={saving}
            className="rounded bg-glow px-6 py-2 text-sm font-medium text-void hover:bg-glow/90 disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save Settings"}
          </button>
        </div>
      </div>
    </div>
  );
}
