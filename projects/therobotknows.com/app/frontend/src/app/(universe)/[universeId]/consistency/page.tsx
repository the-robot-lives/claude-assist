"use client";

import * as React from "react";
import { useParams } from "next/navigation";
import { consistencyApi, type ConsistencyIssue } from "@/lib/api";
import { cn } from "@/lib/cn";
import { Loader2 } from "lucide-react";

export default function ConsistencyPage() {
  const { universeId } = useParams() as { universeId: string };
  const [issues, setIssues] = React.useState<ConsistencyIssue[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [running, setRunning] = React.useState(false);
  const [filter, setFilter] = React.useState<"open" | "all">("open");
  const [error, setError] = React.useState<string | null>(null);

  const load = React.useCallback(async () => {
    setLoading(true);
    try {
      const res = await consistencyApi.list(universeId, filter);
      setIssues(res.issues || []);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load");
    } finally {
      setLoading(false);
    }
  }, [universeId, filter]);

  React.useEffect(() => {
    load();
  }, [load]);

  async function runChecks() {
    setRunning(true);
    setError(null);
    try {
      await consistencyApi.run(universeId);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Check run failed");
    } finally {
      setRunning(false);
    }
  }

  async function resolve(id: string, status: string) {
    await consistencyApi.resolve(universeId, id, { status });
    await load();
  }

  return (
    <div className="max-w-3xl mx-auto px-6 py-10">
      <div className="flex items-start justify-between gap-4 mb-8 flex-wrap">
        <div>
          <h1 className="font-serif text-[28px] font-bold text-ink mb-1">
            Consistency
          </h1>
          <p className="font-sans text-[14px] text-ink-secondary">
            v0.1: duplicate names, orphaned links, lite timeline spans.
          </p>
        </div>
        <button
          type="button"
          onClick={runChecks}
          disabled={running}
          className="rounded-lg bg-accent text-white px-4 py-2 text-[14px] disabled:opacity-60"
        >
          {running ? (
            <span className="inline-flex items-center gap-2">
              <Loader2 className="animate-spin" size={14} /> Running…
            </span>
          ) : (
            "Run checks"
          )}
        </button>
      </div>

      <div className="flex gap-2 mb-6">
        {(["open", "all"] as const).map((f) => (
          <button
            key={f}
            type="button"
            onClick={() => setFilter(f)}
            className={cn(
              "font-mono text-[11px] uppercase px-3 py-1.5 rounded-full border",
              filter === f
                ? "border-accent bg-accent-muted text-accent"
                : "border-rule text-ink-tertiary",
            )}
          >
            {f}
          </button>
        ))}
      </div>

      {error && (
        <p className="mb-4 text-[13px] text-flag-warn bg-flag-warn-muted px-3 py-2 rounded-md">
          {error}
        </p>
      )}

      {loading ? (
        <div className="flex items-center gap-2 text-ink-secondary">
          <Loader2 className="animate-spin" size={16} /> Loading…
        </div>
      ) : issues.length === 0 ? (
        <div className="border border-dashed border-rule rounded-xl p-10 text-center text-ink-secondary">
          No open issues. Run checks after editing entries.
        </div>
      ) : (
        <ul className="space-y-4">
          {issues.map((issue) => (
            <li
              key={issue.id}
              className="border border-rule rounded-xl p-5 bg-surface"
            >
              <div className="flex items-center gap-2 mb-2">
                <span
                  className={cn(
                    "font-mono text-[10px] uppercase tracking-wide px-2 py-0.5 rounded-full",
                    issue.severity === "error" &&
                      "bg-flag-warn-muted text-flag-warn",
                    issue.severity === "warning" &&
                      "bg-flag-warn-muted text-ink",
                    issue.severity === "suggestion" &&
                      "bg-accent-muted text-accent",
                  )}
                >
                  {issue.severity}
                </span>
                <span className="font-mono text-[10px] text-ink-tertiary uppercase">
                  {issue.kind}
                </span>
                <span className="font-mono text-[10px] text-ink-tertiary ml-auto">
                  {issue.status}
                </span>
              </div>
              <h3 className="font-serif text-[18px] font-semibold text-ink mb-2">
                {issue.title}
              </h3>
              <p className="font-sans text-[14px] text-ink-secondary mb-4">
                {issue.detail}
              </p>
              {issue.status === "open" && (
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => resolve(issue.id, "resolved")}
                    className="font-mono text-[11px] uppercase border border-rule rounded-lg px-3 py-1.5"
                  >
                    Resolve
                  </button>
                  <button
                    type="button"
                    onClick={() => resolve(issue.id, "dismissed")}
                    className="font-mono text-[11px] uppercase border border-rule rounded-lg px-3 py-1.5"
                  >
                    Dismiss
                  </button>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
